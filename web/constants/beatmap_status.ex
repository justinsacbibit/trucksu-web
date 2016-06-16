defmodule Trucksu.Constants.BeatmapStatus do

  @ranked_status_not_submitted -1
  @ranked_status_up_to_date 2
  @ranked_status_update_available 1

  def not_submitted, do: @ranked_status_not_submitted
  def up_to_date, do: @ranked_status_up_to_date
  def update_available, do: @ranked_status_update_available
end

