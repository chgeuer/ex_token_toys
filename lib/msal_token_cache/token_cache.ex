defmodule MsalTokenCache.TokenCache do
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_state(pid \\ __MODULE__) do
    GenServer.call(pid, :get_state)
  end

  def reload_from_disk(pid \\ __MODULE__) do
    GenServer.cast(pid, :reload_from_disk)
  end

  def save_to_disk(pid \\ __MODULE__) do
    GenServer.cast(pid, :save_to_disk)
  end

  # Server API

  @impl true
  def init(state) do
    :fs.start_link(:msal_token_cache_dir, MsalTokenCacheParser.msal_token_cache_dir())
    :fs.subscribe(:msal_token_cache_dir)

    {:ok, state, {:continue, :load_from_disk}}
  end

  @impl true
  def handle_continue(:load_from_disk, _state) do
    case MsalTokenCacheParser.load_from_user_home() do
      {:ok, state} ->
        {:noreply, state}

      {:error, :enoent} ->
        {:error, :stop,
         "Token cache file not found (#{MsalTokenCacheParser.msal_token_cache_file()})"}

      err ->
        raise err
    end
  end

  @impl true
  def handle_info({_sender, {:fs, :file_event}, {filename, [event]}}, state)
      when event in [:created, :modified, :renamed] do
    if Path.absname(filename) == MsalTokenCacheParser.msal_token_cache_file() do
      {:noreply, state, {:continue, :load_from_disk}}
    else
      {:noreply, state}
    end
  end

  def handle_info({_sender, {:fs, :file_event}, {_filename, _events}}, state),
    do: {:noreply, state}

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:reload_from_disk, _state) do
    {:ok, state} = MsalTokenCacheParser.load_from_user_home()

    {:noreply, state}
  end

  @impl true
  def handle_cast(:save_to_disk, state) do
    :ok = MsalTokenCacheParser.write_to_user_home(state)

    {:noreply, state}
  end
end
