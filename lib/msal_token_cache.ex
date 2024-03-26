defmodule MsalTokenCache do
  use Application

  alias MsalTokenCache.TokenCache

  def get_state(), do: TokenCache.get_state()

  def reload_from_disk(), do: TokenCache.reload_from_disk()

  def overwrite_state(state), do: TokenCache.overwrite_state(state)

  def save_to_disk(), do: TokenCache.save_to_disk()

  def add_token_response(token_response), do: TokenCache.add_token_response(token_response)

  @impl true
  def start(_type, _args) do
    # Although we don't use the supervisor name below directly,
    # it can be useful when debugging or introspecting the system.
    MsalTokenCache.Supervisor.start_link(name: MsalTokenCache.Supervisor)
  end
end
