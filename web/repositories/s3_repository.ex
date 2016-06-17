defmodule Trucksu.S3Repository do
  require Logger

  def get_file(bucket, filename) do
    case ExAws.S3.get_object(bucket, "#{filename}") do
      {:error, {:http_error, 404, _}} ->
        {:error, :not_found}
      {:error, error} ->
        Logger.error "Failed to get object \"#{filename}\" from S3 bucket \"#{bucket}\""
        Logger.error inspect error
        {:error, error}
      {:ok, %{body: file_content}} ->
        {:ok, file_content}
    end
  end
  def get_file!(bucket, filename) do
    ExAws.S3.get_object!(bucket, "#{filename}")
  end

  def put_file(bucket, filename, contents) do
    case ExAws.S3.put_object(bucket, filename, contents) do
      {:ok, _} ->
        :ok
      {:error, error} ->
        Logger.error "Failed to put file \"#{filename}\" to S3 bucket \"#{bucket}\""
        Logger.error inspect error
        {:error, error}
    end
  end
  def put_file!(bucket, filename, contents) do
    ExAws.S3.put_object!(bucket, filename, contents)
  end
end

