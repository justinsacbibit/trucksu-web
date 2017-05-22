defmodule Trucksu.ScoreController do
  use Trucksu.Web, :controller
  require Logger
  use Bitwise
  alias Trucksu.{
    OsuBeatmapFetcher,
    PerformanceGraph,
    Performance,
    Session,
    Constants,
    ServiceClients,

    Repo,
    OsuBeatmap,
    OsuUserAccessPoint,
    Score,
    ScoreProcessList,
    User,
  }
  alias Trucksu.Helpers.Mods

  @bancho_url Application.get_env(:trucksu, :bancho_url)
  @bot_url Application.get_env(:trucksu, :bot_url)
  @server_cookie Application.get_env(:trucksu, :server_cookie)
  @replay_file_bucket Application.get_env(:trucksu, :replay_file_bucket)

  def create(conn, %{"osuver" => osuver} = params) do
    key = "osu!-scoreburgr---------#{osuver}"

    actually_create(conn, params, key)
  end

  def create(conn, params) do
    key = "h89f2-890h2h89b34g-h80g134n90133"

    actually_create(conn, params, key)
  end

  defp decrypt(ciphertext, key, iv) do
    plaintext = ServiceClients.Decryption.decrypt(ciphertext, key, iv)

    # Strip out trailing weird bytes
    plaintext = Regex.replace(~r/\p{Cc}*$/u, plaintext, "")

    plaintext
  end

  defp check_authentication(username, password_md5) do
    case Session.authenticate(username, password_md5, true) do
      {:error, _reason} ->
        # TODO: Return a 403 instead of 500
        raise "Invalid username or password"
      _ ->
        :ok
    end
  end

  defp fetch_beatmap(beatmap_file_md5) do
    case OsuBeatmapFetcher.fetch(beatmap_file_md5) do
      {:error, :beatmap_not_found} ->
        :stop
      _ ->
        :ok
    end
  end

  defp actually_create(conn, %{"score" => score, "iv" => iv, "pass" => password_md5} = params, key) do

    decrypted_score = decrypt(score, key, iv)
    score_data = String.split(decrypted_score, ":")

    [
      beatmap_file_md5,
      username | _
    ] = score_data

    username = String.rstrip(username)

    result =
      with :ok <- check_authentication(username, password_md5),
        do: fetch_beatmap(beatmap_file_md5)

    if result == :ok do
      keep_creating(conn, params, key, score_data, username)
    else
      conn |> html("")
    end
  end

  defp keep_creating(conn, %{"iv" => iv, "score_file" => replay} = params, key, score_data, username) do

    [
      beatmap_file_md5,
      _username,
      _score_checksum, # TODO: Use to avoid duplicate scores
      count_300,
      count_100,
      count_50,
      count_geki,
      count_katu,
      count_miss,
      score,
      max_combo,
      full_combo,
      rank,
      mods,
      pass,
      game_mode,
      score_datetime,
      raw_version,
    ] = score_data

    trimmed_length = raw_version |> String.strip |> String.length

    bad_flag = (String.length(raw_version) - trimmed_length) &&& ~~~4

    version = String.strip(raw_version)
    encryption_version = params["osuver"]
    if encryption_version && encryption_version != version do
      raise "version mismatch"
    end

    pass = pass == "True"

    process_list = if pass do
      pl = conn.params["pl"]
      decrypt(pl, key, iv)
    else
      ""
    end

    user = Repo.one! from u in User,
      join: s in assoc(u, :stats),
      where: s.game_mode == ^game_mode,
      where: u.username == ^username,
      preload: [stats: s]
    [stats] = user.stats

    security_hash = decrypt(conn.params["s"], key, iv) |> String.strip
    security_hash_parts = String.split(security_hash, ":")
    if length(security_hash_parts) < 4 do
      raise "missinginfo"
    end

    [
      osu_md5,
      _mac_address_list,
      mac_md5,
      unique_md5
      | _
    ] = security_hash_parts

    disk_md5 = if length(security_hash_parts) > 4 do
      Enum.at(security_hash_parts, 4)
    else
      nil
    end

    Task.start(fn -> save_access_point(osu_md5, mac_md5, unique_md5, disk_md5, user) end)

    if pass do
      case String.length(process_list) do
        0 ->
          raise "missinginfo"
        _ ->
          :ok
      end
    end

    full_combo = case full_combo do
      "True" -> 1
      _ -> 0
    end

    # exited = params["x"] == "1"

    {count_300, _} = Integer.parse(count_300)
    {count_100, _} = Integer.parse(count_100)
    {count_50, _} = Integer.parse(count_50)
    {count_miss, _} = Integer.parse(count_miss)

    {mods, _} = Integer.parse(mods)

    ignored_mods = [Constants.Mods.relax, Constants.Mods.auto, Constants.Mods.autopilot]
    cond do
      Enum.any?(ignored_mods, &(Mods.is_mod_enabled(mods, &1))) ->
        # RX, Auto, or AP
        Logger.info "#{user.username} submitted a score with RX, Auto, or AP, ignoring."

        # TODO: Don't call render func
        render conn, "response.raw", data: <<>>


      pass ->
        top_score = Repo.one from s in Score,
          join: ob in assoc(s, :osu_beatmap),
          join: u in assoc(s, :user),
          where: ob.file_md5 == ^beatmap_file_md5
            and u.username == ^username
            and s.game_mode == ^game_mode,
          order_by: [desc: s.score],
          limit: 1

        {score, _} = Integer.parse(score)

        score_difference = case top_score do
          nil ->
            score
          top_score ->
            cond do
              score > top_score ->
                score - top_score.score
              true ->
                0
            end
        end

        new_score = stats.ranked_score + score_difference

        total_points_of_hits = count_50 * 50 + count_100 * 100 + count_300 * 300
        total_number_of_hits = count_miss + count_50 + count_100 + count_300
        accuracy = total_points_of_hits / (total_number_of_hits * 300)

        {:ok, score} = Repo.transaction fn ->

          score = Score.changeset(%Score{}, %{
            file_md5: beatmap_file_md5,
            user_id: user.id,
            score: score,
            max_combo: max_combo,
            full_combo: full_combo,
            mods: mods,
            count_300: count_300,
            count_100: count_100,
            count_50: count_50,
            katu_count: count_katu,
            geki_count: count_geki,
            miss_count: count_miss,
            time: score_datetime,
            game_mode: game_mode,
            accuracy: accuracy,
            pass: pass,
            has_replay: true,
            rank: rank,
          })

          score = Repo.insert! score

          if bad_flag != 0 do
            Logger.error "#{username} submitted a score with bad_flag! score.id=#{score.id}, bad_flag=#{bad_flag}"
          end

          Task.start(fn -> save_process_list(user, score, process_list, version) end)

          score = case Performance.calculate(score) do
            {:ok, nil} ->
              score

            {:ok, pp} ->
              Logger.info "Calculated a pp of #{pp} for #{user.username} for score id #{score.id}"
              changeset = Ecto.Changeset.change(score, %{pp: pp})
              Repo.update! changeset

            {:error, error} ->
              Logger.error "Failed to calculate pp for score: #{inspect score}, error: #{inspect error}"

              score
          end

          Task.start(fn -> upload_replay(replay.path, score.id, user.username) end)

          user_id = user.id

          [pp: new_pp, accuracy: new_accuracy] = Performance.calculate_stats_for_user(user_id, game_mode)

          Repo.update! Ecto.Changeset.change stats,
            ranked_score: new_score,
            total_score: new_score,
            playcount: stats.playcount + 1,
            total_hits: stats.total_hits + count_300 + count_100 + count_50,
            accuracy: new_accuracy,
            pp: new_pp

          score = Repo.preload score, :osu_beatmap

          score
        end

        Logger.info "Inserted score: #{inspect score}"

        if score.pp do
          Task.start(fn -> notify_services_of_score(score, user) end)
        end

        # TODO: Use Phoenix.PubSub (or another form of pubsub) to invalidate the cache
        PerformanceGraph.Server.invalidate(user.id, game_mode)
        Trucksu.UserScoresCache.invalidate(user.id, game_mode)

        # TODO: Don't call render func
        render conn, "response.raw", data: build_response(score)
      true ->
        # User failed or retried, or exited?

        user_stats = Ecto.Changeset.change stats,
          playcount: stats.playcount + 1,
          total_hits: stats.total_hits + count_300 + count_100 + count_50

        Repo.update! user_stats

        conn
        |> html("")
    end
  end

  defp save_access_point(osu_md5, mac_md5, unique_md5, disk_md5, user) do
    changeset = OsuUserAccessPoint.changeset(%OsuUserAccessPoint{}, %{
      osu_md5: osu_md5,
      mac_md5: mac_md5,
      unique_md5: unique_md5,
      disk_md5: disk_md5,
      user_id: user.id,
    })
    case Repo.insert changeset do
      {:error, %{constraints: [%{field: :osu_md5, type: :unique}]}} ->
        Logger.debug "Ignoring duplicate access point"
      {:error, error} ->
        Logger.error "Unable to save access point for #{user.username}: #{inspect error}"
      _ ->
        :ok
    end
  end

  defp save_process_list(user, score, process_list, version) do
    changeset = ScoreProcessList.changeset(%ScoreProcessList{}, %{
      user_id: user.id,
      score_id: score.id,
      process_list: process_list,
      version: version,
    })
    case Repo.insert changeset do
      {:error, error} ->
        Logger.error "Unable to save process list for #{user.username} score with id #{score.id}: #{inspect error}"
      _ ->
        :ok
    end
  end

  defp upload_replay(replay_path, score_id, username) do
    replay_file_content = File.read!(replay_path)
    ExAws.S3.put_object!(@replay_file_bucket, "#{score_id}", replay_file_content) |> ExAws.request
    Logger.info "Uploaded replay for #{username}, score id #{score_id}, byte size: #{replay_file_content |> byte_size}"
  end

  defp notify_services_of_score(score, user) do
    # Check if it's first place
    user_id = user.id
    game_mode = score.game_mode
    score_id = score.id
    query = from sc in Score,
      join: sc_ in fragment("
        SELECT id
          FROM (
            SELECT
              sc.id,
              user_id,
              sc.game_mode,
              row_number()
              OVER (PARTITION BY sc.file_md5, sc.game_mode
                 ORDER BY score DESC) score_rank
            FROM scores sc
            JOIN users u
              on sc.user_id = u.id
            WHERE sc.pass AND NOT u.banned
          ) x
        WHERE user_id = (?) AND score_rank = 1 AND game_mode = (?)
      ", ^user_id, ^game_mode),
        on: sc_.id == sc.id,
      where: sc.id == ^score_id
    is_first_place = case Repo.one(query) do
      nil -> false
      _ -> true
    end

    file_md5 = score.file_md5
    osu_beatmap = Repo.one! from ob in OsuBeatmap,
      join: obs in assoc(ob, :beatmapset),
      where: ob.file_md5 == ^file_md5,
      preload: [beatmapset: obs]

    # TODO: Error logging
    data = %{
      "cookie" => @server_cookie,
      "event_type" => "pp",
      "pp" => "#{round score.pp}",
      "user_id" => user.id,
      "username" => user.username,
      "beatmap_id" => "#{osu_beatmap.id}",
      "version" => osu_beatmap.version,
      "artist" => osu_beatmap.beatmapset.artist,
      "title" => osu_beatmap.beatmapset.title,
      "creator" => osu_beatmap.beatmapset.creator,
      "mods" => score.mods,
      "rank" => score.rank,
      "accuracy" => score.accuracy,
      "max_combo" => score.max_combo,
      "time" => score.time,
      "is_first_place" => is_first_place,
    }
    json = Poison.encode!(data)

    Task.start(fn ->
      response = HTTPoison.post(@bancho_url <> "/event", json, [{"Content-Type", "application/json"}], timeout: 20000, recv_timeout: 20000)

      case response do
        {:ok, _response} ->
          Logger.warn "Sent pp event to Bancho: #{inspect data}"
        {:error, response} ->
          Logger.error "Failed to send pp event to Bancho: #{inspect response}"
      end
    end)

    Task.start(fn ->
      response = HTTPoison.post(@bot_url <> "/event", json, [{"Content-Type", "application/json"}], timeout: 20000, recv_timeout: 20000)

      case response do
        {:ok, _response} ->
          Logger.warn "Sent pp event to Bot: #{inspect data}"
        {:error, response} ->
          Logger.error "Failed to send pp event to Bot: #{inspect response}"
      end
    end)
  end

  defp build_response(score) do
    "beatmapId:#{1}"
    <> "|beatmapSetId:#{2}"
    <> "|beatmapPlaycount:#{5}"
    <> "|beatmapPasscount:#{4}"
    <> "|approvedDate:#{"2014-05-05 20:02:30"}\n"
    <> "chartId:#{"overall"}"
    <> "|chartName:#{"Overall Ranking"}"
    <> "|chartEndDate:#{""}"
    <> "|beatmapRankingBefore:#{1}"
    <> "|beatmapRankingAfter:#{1}"
    <> "|rankedScoreBefore:#{1}"
    <> "|rankedScoreAfter:#{1}"
    <> "|totalScoreBefore:#{1}"
    <> "|totalScoreAfter:#{1}"
    <> "|playCountBefore:#{1}"
    <> "|accuracyBefore:#{1}"
    <> "|accuracyAfter:#{1}"
    <> "|rankBefore:#{1}"
    <> "|rankAfter:#{1}"
    <> "|toNextRank:#{1}"
    <> "|toNextRankUser:#{"MEME"}"
    <> "|achievements:#{""}"
    <> "|achievements-new:#{""}"
    <> "|onlineScoreId:#{score.id}\n"
  end
end
