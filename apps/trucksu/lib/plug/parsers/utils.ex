defmodule TruckPlug.Conn.Utils do
  @doc """
  Validates the given binary is valid UTF-8.
  """
  @spec validate_utf8!(binary, module, binary) :: :ok | no_return
  def validate_utf8!(binary, exception, context)
  def validate_utf8!(<<_ :: utf8, t :: binary>>, exception, context) do
    validate_utf8!(t, exception, context)
  end

  def validate_utf8!(<<h, _ :: binary>>, exception, context) do
    raise exception,
      message: "invalid UTF-8 on #{context}, got byte #{h}"
  end

  def validate_utf8!(<<>>, _exception, _context) do
    :ok
  end
end
