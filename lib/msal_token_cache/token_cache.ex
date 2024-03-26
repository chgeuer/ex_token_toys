defmodule MsalTokenCache.TokenCache do
  require Logger
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  def overwrite_state(state) do
    GenServer.call(__MODULE__, {:overwrite_state, state})
  end

  def reload_from_disk() do
    GenServer.cast(__MODULE__, :reload_from_disk)
  end

  def save_to_disk() do
    GenServer.cast(__MODULE__, :save_to_disk)
  end

  def add_token_response(token_response) do
    GenServer.call(__MODULE__, {:add_token_response, token_response})
  end

  # Server API

  @impl true
  def init(_state) do
    :fs.start_link(:msal_token_cache_dir, MsalTokenCacheParser.msal_token_cache_dir())
    :fs.subscribe(:msal_token_cache_dir)

    {:ok, nil, {:continue, :load_from_disk}}
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
  def handle_continue(:save_to_disk, state) do
    MsalTokenCacheParser.write_to_user_home(state)

    {:noreply, state}
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
  def handle_call({:overwrite_state, new_state}, _from, _state) do
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:add_token_response, token_response}, _from, state) do
    state = MsalTokenCacheParser.update_state_with_token_response(state, token_response)

    {:reply, :ok, state, {:continue, :save_to_disk}}
  end

  @impl true
  def handle_cast(:reload_from_disk, _state) do
    {:ok, state} = MsalTokenCacheParser.load_from_user_home()

    {:noreply, state}
  end

  @impl true
  def handle_cast(:save_to_disk, state) do
    MsalTokenCacheParser.write_to_user_home(state)

    {:noreply, state}
  end
end
