defmodule MsalTokenCache.TokenRetriever do
  require Logger
  use GenServer

  # @datastore MsalTokenCache.TokenCache

  defstruct [:audience]

  def start_child(audience) when is_binary(audience) do
    DynamicSupervisor.start_child(
      MsalTokenCache.TokenRetrievalSupervisor,
      {__MODULE__, %__MODULE__{audience: audience}}
    )
  end

  def start_link(%__MODULE__{} = state) do
    GenServer.start_link(__MODULE__, state, name: String.to_atom(state.audience))
  end

  @impl true
  def init(arg) do
    Logger.info("init: #{inspect(self())} arg: #{inspect(arg)}")
    Process.flag(:trap_exit, true)

    ok(arg)
  end

  def child_spec(%__MODULE__{} = state) do
    %{
      id: state.audience,
      start: {__MODULE__, :start_link, [state]}
    }
  end

  defp ok(arg), do: {:ok, arg}

  # defp noreply(state), do: {:noreply, state}
  # defp reply(state, response), do: {:reply, response, state}
end
