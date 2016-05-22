defmodule Trucksu.OsuBeatmapsetFetcher do
  require Logger
  alias Trucksu.{
    Osu,

    OsuBeatmapset,
    Repo,
    OsuBeatmap,
  }

  @beatmap_status_approved 2
  @beatmap_status_ranked 1

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

  defp update_beatmapset(osu_beatmapset, [first_beatmap | _] = beatmap_maps) do
    Logger.warn "Updating beatmapset with id #{osu_beatmapset.id} in the database"

    {:ok, result} = Repo.transaction(fn ->
      changeset = OsuBeatmapset.changeset_from_api(osu_beatmapset, first_beatmap)
      case Repo.update changeset do
        {:ok, _osu_beatmapset} ->
          Logger.warn "Updated beatmapset with id #{osu_beatmapset.id} in the database"

          # TODO: Remove beatmaps that are no longer in the set, but rather than
          # deleting the beatmaps, "stage" it for deletion so that we can manually
          # confirm that the beatmapset is unsubmitted before wiping scores. Also,
          # we probably want to notify users that the score was wiped.

          # Find maps that are in our database, but are no longer in the set
          # MapSet.difference(MapSet.new(), MapSet.new())

          for beatmap_map <- beatmap_maps do
            case Repo.get OsuBeatmap, beatmap_map["beatmap_id"] do
              nil ->
                changeset = OsuBeatmap.changeset_from_api(%OsuBeatmap{}, beatmap_map)
                case Repo.insert changeset do
                  {:ok, _osu_beatmap} ->
                    :ok
                  {:error, error} ->
                    Logger.error "Error occurred when trying to insert a beatmap from osu! API"
                    Logger.error inspect error
                    :ok
                end
              osu_beatmap ->
                # TODO: Wipe scores, and notify users that the score was wiped.
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
    # TODO: Rate limit
    Logger.warn "Fetch beatmapset #{beatmapset_id}"

    case Repo.get OsuBeatmapset, beatmapset_id do
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
        if beatmapset_not_ranked?(osu_beatmapset) do
          # TODO: use osu_beatmapset.last_check to limit API calls
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

              # It's unsubmitted, so delete it if it's in the database
              # TODO: Add cascade delete, so that deleting the set will delete the
              # beatmaps and associated scores

              # TODO: Rather than deleting the beatmapset, "stage" it for deletion
              # so that we can manually confirm that the beatmapset is unsubmitted
              # before wiping scores. Also, we probably want to notify users that
              # the score will be wiped.

              true

            {:error, error} ->
              Logger.error "Failed to get beatmapset #{beatmapset_id} from the osu! API"
              Logger.error inspect error

              # failed
              false
          end
        end
    end
  end
end
