defmodule MsalTokenCache.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {MsalTokenCache.TokenCache, name: MsalTokenCache.TokenCache},
      {DynamicSupervisor, name: MsalTokenCache.TokenRetrievalSupervisor}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
