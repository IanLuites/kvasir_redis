defmodule Kvasir.RedisTest do
  use ExUnit.Case
  doctest Kvasir.Redis

  test "greets the world" do
    assert Kvasir.Redis.hello() == :world
  end
end
