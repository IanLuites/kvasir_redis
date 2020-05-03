if Code.ensure_loaded?(Kvasir.Agent) do
  defmodule Kvasir.Cache.Redis do
    alias Raditz.PoolBoy, as: Redis
    @behaviour Kvasir.Agent.Cache

    @nils <<131, 119, 3, 110, 105, 108>>

    @impl Kvasir.Agent.Cache
    def init(agent, partition, opts),
      do: {:ok, Redis.child_spec(:"#{agent}.Cache#{partition}", opts)}

    @impl Kvasir.Agent.Cache
    def track_command(agent, partition, id) do
      pid = :"#{agent}.Cache#{partition}"
      Redis.command(pid, ["INCR", command_counter(agent, id)])
    end

    @impl Kvasir.Agent.Cache
    def save(agent, partition, id, data, offset, command_counter) do
      pid = :"#{agent}.Cache#{partition}"

      state = {offset, command_counter, data}
      payload = :erlang.term_to_binary(state, compressed: 9, minor_version: 2)

      with {:ok, "OK"} <- Redis.command(pid, ["SET", key(agent, id), payload]), do: :ok
    end

    @impl Kvasir.Agent.Cache
    def load(agent, partition, id) do
      pid = :"#{agent}.Cache#{partition}"

      with {:ok, [state, counter]} <-
             Redis.pipeline(pid, [
               ["GET", key(agent, id)],
               ["GET", command_counter(agent, id)]
             ]) do
        counter = String.to_integer(counter || "0")

        {offset, commands, data} =
          case :erlang.binary_to_term(state || @nils) do
            nil -> {Kvasir.Offset.create(), 0, nil}
            {o, s} -> {o, 0, s}
            {o, c, s} -> {o, c, s}
          end

        if counter == commands do
          {:ok, offset, data}
        else
          {:error, :state_counter_mismatch, counter, commands}
        end
      end
    end

    @impl Kvasir.Agent.Cache
    def delete(agent, partition, id) do
      pid = :"#{agent}.Cache#{partition}"

      Redis.pipeline(pid, [
        ["DEL", key(agent, id)],
        ["DEL", command_counter(agent, id)]
      ])

      :ok
    end

    @spec key(module, term) :: String.t()
    defp key(agent, id), do: "cache:#{inspect(agent)}:#{id}"

    @spec command_counter(module, term) :: String.t()
    defp command_counter(agent, id), do: "cache_counter:#{inspect(agent)}:#{id}"
  end
end
