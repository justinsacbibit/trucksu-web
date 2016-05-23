defmodule Trucksu.OsuBeatmapsetFetcher do
  require Logger
  import Ecto.Query, only: [from: 2]
  alias Trucksu.{
    Osu,

    OsuBeatmapset,
    Repo,
    OsuBeatmap,
  }

  @beatmap_status_approved 2
  @beatmap_status_ranked 1

  @hour_threshold_before_updating_pending_maps 2

  defp insert_beatmapset([first_beatmap | _] = beatmap_maps) do
    beatmapset_id = first_beatmap["beatmapset_id"]
    Logger.warn "Inserting a new beatmapset with id #{beatmapset_id} into the database"

    {:ok, result} = Repo.transaction(fn ->
      changeset = OsuBeatmapset.changeset_from_api(%OsuBeatmapset{}, first_beatmap)
      case Repo.insert changeset do
        {:ok, _osu_beatmapset} ->
          Logger.warn "Inserted a new beatmapset with id #{beatmapset_id} into the database"

          # Insert all beatmaps in the set. Returns {:error, error} on the first
          # beatmap insertion error.
          Enum.reduce_while(beatmap_maps, :ok, fn(beatmap_map, _acc) ->
            changeset = OsuBeatmap.changeset_from_api(%OsuBeatmap{}, beatmap_map)
            case Repo.insert changeset do
              {:ok, _osu_beatmap} ->
                {:cont, :ok}
              {:error, error} ->
                # Stop the reduction here
                Logger.error "Error occurred when trying to insert a beatmap from osu! API"
                Logger.error inspect error
                {:halt, {:error, error}}
            end
          end)

        {:error, error} ->
          Logger.error "Error occurred when trying to insert beatmapset with id #{beatmapset_id} from osu! API"
          Logger.error inspect error
          {:error, error}
      end
    end)

    result
  end

  defp delete_beatmap(osu_beatmap) do
    osu_beatmap = Repo.preload osu_beatmap, :scores
    for score <- osu_beatmap.scores do
      # TODO: Record deletion
    end
    case Repo.delete osu_beatmap do
      {:ok, osu_beatmap} ->
        :ok
      {:error, error} ->
        Logger.error "Error occurred when trying to delete osu_beatmap"
        Logger.error inspect error
        :ok
    end
  end

  defp insert_beatmap(beatmap_map) do
    changeset = OsuBeatmap.changeset_from_api(%OsuBeatmap{}, beatmap_map)
    case Repo.insert changeset do
      {:ok, _osu_beatmap} ->
        :ok
      {:error, error} ->
        Logger.error "Error occurred when trying to insert a beatmap from osu! API"
        Logger.error inspect error
        :ok
    end
  end

  defp update_beatmapset(osu_beatmapset, [first_beatmap | _] = beatmap_maps) do
    Logger.warn "Updating beatmapset with id #{osu_beatmapset.id} in the database"

    {:ok, result} = Repo.transaction(fn ->
      changeset = OsuBeatmapset.changeset_from_api(osu_beatmapset, first_beatmap)
      case Repo.update changeset do
        {:ok, osu_beatmapset} ->
          Logger.warn "Updated beatmapset with id #{osu_beatmapset.id} in the database"

          # Find maps that are in our database, but are no longer in the set
          for existing_beatmap <- osu_beatmapset.beatmaps,
              not Enum.any?(beatmap_maps, fn(%{"beatmap_id" => beatmap_id}) -> "#{existing_beatmap.id}" == "#{beatmap_id}" end) do
            delete_beatmap(existing_beatmap)
          end

          for beatmap_map <- beatmap_maps do
            case Repo.get OsuBeatmap, beatmap_map["beatmap_id"] do
              nil ->
                insert_beatmap(beatmap_map)
              osu_beatmap ->
                if osu_beatmap.file_md5 != beatmap_map["file_md5"] do
                  delete_beatmap(osu_beatmap)
                  insert_beatmap(beatmap_map)
                else
                  changeset = OsuBeatmap.changeset_from_api(osu_beatmap, beatmap_map)
                  case Repo.update changeset do
                    {:ok, _osu_beatmap} ->
                      :ok
                    {:error, error} ->
                      Logger.error "Error occurred when trying to update a beatmap from osu! API"
                      Logger.error inspect error
                      :ok
                  end
                end
            end
          end

        {:error, error} ->
          Logger.error "Error occurred when trying to update beatmapset with id #{osu_beatmapset.id} from osu! API"
          Logger.error inspect error
          {:error, error}
      end
    end)

    result
  end

  defp beatmapset_not_ranked?(osu_beatmapset) do
    osu_beatmapset.approved != @beatmap_status_approved
    && osu_beatmapset.approved != @beatmap_status_ranked
  end

  # Fetch the beatmapset_id from the osu! API
  def fetch(beatmapset_id) do
    # 1 call every 2 hours
    rate_limit = ExRated.check_rate("set-#{beatmapset_id}", 7_200_000, 1)

    # TODO: Refactor so that the rate_limit only disables the API call
    case rate_limit do
      {:error, _} ->
        false
      _ ->
        actually_fetch(beatmapset_id)
    end
  end

  defp actually_fetch(beatmapset_id) do
    query = from obs in OsuBeatmapset,
      join: ob in assoc(obs, :beatmaps),
      where: obs.id == ^beatmapset_id,
      preload: [beatmaps: ob]
    case Repo.one query do
      nil ->
        case Osu.get_beatmaps(s: beatmapset_id) do
          {:ok, %HTTPoison.Response{body: [_first_beatmap | _] = api_beatmaps}} ->
            case insert_beatmapset(api_beatmaps) do
              {:error, _error} ->
                false
              _ ->
                true
            end

          {:ok, body} ->
            Logger.error "Looks like beatmapset #{beatmapset_id} doesn't exist"
            Logger.error inspect body

            # beatmap doesn't exist
            true

          {:error, error} ->
            Logger.error "Failed to get beatmapset #{beatmapset_id} from the osu! API"
            Logger.error inspect error

            # failed
            false

        end
      osu_beatmapset ->
        # TODO: Uncomment once we figure out why beatmapsets are getting inserted
        # without all of their beatmaps
        # if beatmapset_not_ranked?(osu_beatmapset) do
          hours_since_last_check = Timex.DateTime.diff(Timex.DateTime.now, osu_beatmapset.last_check, :hours)
          if hours_since_last_check <= @hour_threshold_before_updating_pending_maps do
            true
          else
            case Osu.get_beatmaps(s: beatmapset_id) do
              {:ok, %HTTPoison.Response{body: [_first_beatmap | _] = api_beatmaps}} ->
                case update_beatmapset(osu_beatmapset, api_beatmaps) do
                  {:error, _error} ->
                    false
                  _ ->
                    true
                end

              {:ok, body} ->
                Logger.error "Looks like beatmapset #{beatmapset_id} doesn't exist"
                Logger.error inspect body

                # TODO: Add cascade delete, so that deleting the set will delete the
                # beatmaps and associated scores. Also add a way to manually delete
                # the beatmapset, and notify users of the wiped scores.

                # Mark as unsubmitted
                changeset = Ecto.Changeset.change(osu_beatmapset, unsubmitted: true)
                case Repo.update changeset do
                  {:ok, _osu_beatmapset} ->
                    :ok
                  {:error, error} ->
                    Logger.error "Error occurred when trying to mark a beatmapset as unsubmitted"
                    Logger.error inspect error
                    :ok
                end

                true

              {:error, error} ->
                Logger.error "Failed to get beatmapset #{beatmapset_id} from the osu! API"
                Logger.error inspect error

                # failed
                false
            end
          end
        # end
    end
  end
end
