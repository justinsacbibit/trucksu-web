defmodule Trucksu.Accuracy do
  alias Trucksu.Score

  def from_accuracies([]) do
    1
  end

  def from_accuracies(accuracies) do
    {numerator, denominator, _} = Enum.reduce accuracies, {0, 0, 0}, fn accuracy, {numerator, denominator, index} ->
      factor = :math.pow(0.95, index)

      numerator = numerator + accuracy * factor
      denominator = denominator + factor

      {numerator, denominator, index + 1}
    end

    numerator / denominator
  end
end
