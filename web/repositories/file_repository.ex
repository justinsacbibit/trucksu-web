defmodule Trucksu.FileRepository do
  @moduledoc """
  Provides an API for storing and retrieving files.

  Application configuration is used to determine the underlying storage type.

  The bucket parameter should be an atom that is used within the application
  configuration, e.g. `:beatmap_file_bucket`. The repository will retrieve the
  actual folder path or S3 bucket name from the configuration.
  """

  @doc """
  Retrieves a file from the repository.

  If you want to check existence of a file as well as retrieve its contents
  if it exists, you should only call this function.
  """
  def get_file(bucket, filename) do
    bucket = bucket_from_config(bucket)
    filename = "#{filename}"
    repository().get_file(bucket, filename)
  end

  @doc """
  Puts a file into the repository.

  If the file already exists, its contents are overwritten.
  """
  def put_file(bucket, filename, contents) do
    bucket = bucket_from_config(bucket)
    filename = "#{filename}"
    repository().put_file(bucket, filename, contents)
  end
  def put_file!(bucket, filename, contents) do
    bucket = bucket_from_config(bucket)
    filename = "#{filename}"
    repository().put_file!(bucket, filename, contents)
  end

  defp repository() do
    case Application.get_env(:trucksu, :file_repository) do
      :s3 ->
        Trucksu.S3Repository
      :fs ->
        Trucksu.FsRepository
      repository ->
        raise "Invalid repository found in configuration: #{repository}"
    end
  end

  defp bucket_from_config(bucket) do
    Application.get_env(:trucksu, bucket)
  end
end

