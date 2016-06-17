defmodule Trucksu.FsRepository do
  require Logger

  def get_file(folder, filename) do
    path = Path.join(folder, filename)
    case File.read(path) do
      {:error, :enoent} ->
        {:error, :not_found}
      {:error, error} ->
        Logger.error "Failed to get file \"#{filename}\" from folder \"#{folder}\""
        Logger.error inspect error
        {:error, error}
      {:ok, file_content} ->
        {:ok, file_content}
    end
  end
  def get_file!(folder, filename) do
    {:ok, file_content} = get_file(folder, filename)
    file_content
  end

  def put_file(folder, filename, contents) do
    create_folder(folder)

    path = Path.join(folder, filename)
    case File.write(path, contents) do
      {:error, error} ->
        Logger.error "Failed to write file \"#{filename}\" to folder \"#{folder}\""
        Logger.error inspect error
        {:error, error}
      :ok -> :ok
    end
  end
  def put_file!(folder, filename, contents) do
    :ok = put_file(folder, filename, contents)
    :ok
  end

  defp create_folder(folder) do
    File.mkdir_p!(folder)
  end
end

