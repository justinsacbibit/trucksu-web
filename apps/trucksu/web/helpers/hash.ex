defmodule Trucksu.Hash do
  def md5(text) do
    Base.encode16(:erlang.md5(text), case: :lower)
  end
end

