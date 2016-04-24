defmodule Trucksu.BeatmapParser do
  def parse(raw_beatmap_data) do
    parser_url = Application.get_env(:trucksu, :osuparser_url)
    %HTTPoison.Response{body: body} = HTTPoison.post!(parser_url, raw_beatmap_data, [{"Content-Type", "text/plain"}])
    beatmap_data = Poison.Parser.parse! body

    beatmap_data
  end
end

