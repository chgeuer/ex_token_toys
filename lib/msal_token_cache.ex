defmodule MsalTokenCache do
  use Application

  @datastore MsalTokenCache.TokenCache

  def get_state(), do: @datastore.get_state()

  def reload_from_disk(), do: @datastore.reload_from_disk()

  def overwrite_state(state), do: @datastore.overwrite_state(state)

  def save_to_disk(), do: @datastore.save_to_disk()

  @impl true
  def start(_type, _args) do
    # Although we don't use the supervisor name below directly,
    # it can be useful when debugging or introspecting the system.
    MsalTokenCache.Supervisor.start_link(name: MsalTokenCache.Supervisor)
  end
end
