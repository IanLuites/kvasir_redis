if Code.ensure_loaded?(Kvasir.Agent) do
  defmodule Kvasir.Cache.Redis do
    alias Raditz.PoolBoy, as: Redis
    @behaviour Kvasir.Agent.Cache

    @impl Kvasir.Agent.Cache
    def init(agent, opts), do: {:ok, Redis.child_spec(agent, opts)}

    @impl Kvasir.Agent.Cache
    def save(agent, id, data, offset) do
      with {:ok, "OK"} <-
             Redis.command(
               agent,
               [
                 "SET",
                 key(agent, id),
                 :erlang.term_to_binary({offset, data}, compressed: 9, minor_version: 2)
               ]
             ),
           do: :ok
    end

    @impl Kvasir.Agent.Cache
    def load(agent, id) do
      with {:ok, result} when result != nil <- Redis.command(agent, ["GET", key(agent, id)]),
           {offset, data} <- :erlang.binary_to_term(result) do
        {:ok, offset, data}
      else
        {:ok, nil} -> {:error, :not_found}
      end
    end

    @impl Kvasir.Agent.Cache
    def delete(agent, id) do
      Redis.command(agent, ["DEL", key(agent, id)])

      :ok
    end

    @spec key(module, term) :: String.t()
    defp key(agent, id), do: "cache:#{inspect(agent)}:#{id}"
  end
end
