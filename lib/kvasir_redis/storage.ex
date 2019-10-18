defmodule Kvasir.Storage.Redis do
  alias Raditz.PoolBoy, as: Redis
  @behaviour Kvasir.Storage
  require Logger

  @impl Kvasir.Storage
  def child_spec(name, opts \\ []) do
    %{
      id: name,
      start: {__MODULE__, :start_link, [name, opts]}
    }
  end

  def start_link(name, opts) do
    {_, {m, f, arg}, _, _, _, _} = Redis.child_spec(name, opts)

    with {:ok, pid} <- apply(m, f, arg) do
      {:ok, pid}
    end
  end

  @impl Kvasir.Storage
  def contains?(_name, _topic, _offset) do
  end

  @impl Kvasir.Storage
  def freeze(redis, event) do
    {:ok,
     %{
       meta:
         meta = %{
           topic: topic,
           partition: partition,
           offset: offset
         },
       version: version,
       payload: data,
       type: type
     }} = Kvasir.Event.Encoding.encode(event)

    Redis.command(redis, [
      "XADD",
      "cold.#{topic}",
      "#{partition}-#{offset}",
      "type",
      type,
      "version",
      to_string(version),
      "meta",
      Jason.encode!(meta),
      "payload",
      Jason.encode!(data)
    ])
  end

  @impl Kvasir.Storage
  def stream(redis, topic, _opts \\ []) do
    {:ok, events} =
      Redis.command(redis, [
        "XRANGE",
        "cold.#{topic}",
        "-",
        "+"
      ])

    Enum.map(events, &parse_stream/1)
  end

  defp parse_stream([_, ["type", type, "version", version, "meta", meta, "payload", payload]]) do
    # Kvasir.Event.Encoding.decode(
    %{
      type: type,
      version: Version.parse!(version),
      meta: Jason.decode!(meta),
      payload: Jason.decode!(payload)
    }

    # )
  end
end
