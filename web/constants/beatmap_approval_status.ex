defmodule Trucksu.Constants.BeatmapApprovalStatus do
  @qualified 3
  @approved 2
  @ranked 1
  @pending 0
  @wip -1
  @graveyard -2

  def qualified, do: @qualified
  def approved, do: @approved
  def ranked, do: @ranked
  def pending, do: @pending
  def wip, do: @wip
  def graveyard, do: @graveyard
end

