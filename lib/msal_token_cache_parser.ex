defmodule MsalTokenCacheParser do
  require Logger

  defstruct [:access_tokens, :accounts, :id_tokens, :refresh_tokens, :app_metadata]

  defp decode_access_token(
         {key,
          %{
            "cached_at" => cached_at,
            "expires_on" => expires_on,
            "client_id" => client_id,
            "credential_type" => "AccessToken",
            "environment" => environment,
            "extended_expires_on" => extended_expires_on,
            "home_account_id" => home_account_id,
            "realm" => realm,
            "secret" => access_token,
            "target" => target
          }}
       ) do
    %{
      key: key |> parse_key(),
      cached_at: cached_at |> epoch_string_to_datetime(),
      client_id: client_id,
      environment: environment,
      expires_on: expires_on |> epoch_string_to_datetime(),
      extended_expires_on: extended_expires_on |> epoch_string_to_datetime(),
      home_account_id: home_account_id,
      realm: realm,
      access_token: access_token,
      target: target
    }
  end

  defp encode_access_token(%{
         key: %{key: key},
         cached_at: cached_at,
         client_id: client_id,
         environment: environment,
         expires_on: expires_on,
         extended_expires_on: extended_expires_on,
         home_account_id: home_account_id,
         realm: realm,
         access_token: access_token,
         target: target
       }) do
    {key,
     %{
       "cached_at" => cached_at |> datetime_to_epoch_string(),
       "expires_on" => expires_on |> datetime_to_epoch_string(),
       "client_id" => client_id,
       "credential_type" => "AccessToken",
       "environment" => environment,
       "extended_expires_on" => extended_expires_on |> datetime_to_epoch_string(),
       "home_account_id" => home_account_id,
       "realm" => realm,
       "secret" => access_token,
       "target" => target
     }}
  end

  defp decode_refresh_token(
         {key,
          %{
            "client_id" => client_id,
            "credential_type" => "RefreshToken",
            "environment" => environment,
            "family_id" => family_id,
            "home_account_id" => home_account_id,
            "last_modification_time" => last_modification_time,
            "secret" => refresh_token,
            "target" => target
          }}
       ) do
    %{
      key: key |> parse_key(),
      client_id: client_id,
      environment: environment,
      family_id: family_id,
      home_account_id: home_account_id,
      last_modification_time: last_modification_time |> epoch_string_to_datetime(),
      refresh_token: refresh_token,
      target: target
    }
  end

  defp encode_refresh_token(%{
         key: %{key: key},
         client_id: client_id,
         environment: environment,
         family_id: family_id,
         home_account_id: home_account_id,
         last_modification_time: last_modification_time,
         refresh_token: refresh_token,
         target: target
       }) do
    {key,
     %{
       "client_id" => client_id,
       "credential_type" => "RefreshToken",
       "environment" => environment,
       "family_id" => family_id,
       "home_account_id" => home_account_id,
       "last_modification_time" => last_modification_time |> datetime_to_epoch_string(),
       "secret" => refresh_token,
       "target" => target
     }}
  end

  defp decode_account(
         {key,
          %{
            "home_account_id" => home_account_id,
            "environment" => environment,
            "realm" => realm,
            "local_account_id" => local_account_id,
            "username" => username,
            "authority_type" => authority_type
          }}
       ) do
    %{
      key: key,
      home_account_id: home_account_id,
      environment: environment,
      realm: realm,
      local_account_id: local_account_id,
      username: username,
      authority_type: authority_type
    }
  end

  defp encode_account(%{
         key: key,
         home_account_id: home_account_id,
         environment: environment,
         realm: realm,
         local_account_id: local_account_id,
         username: username,
         authority_type: authority_type
       }) do
    {key,
     %{
       "home_account_id" => home_account_id,
       "environment" => environment,
       "realm" => realm,
       "local_account_id" => local_account_id,
       "username" => username,
       "authority_type" => authority_type
     }}
  end

  defp decode_id_token(
         {key,
          %{
            "credential_type" => "IdToken",
            "secret" => id_token,
            "home_account_id" => home_account_id,
            "environment" => environment,
            "realm" => realm,
            "client_id" => client_id
          }}
       ) do
    %{
      key: key |> parse_key(),
      id_token: id_token,
      home_account_id: home_account_id,
      environment: environment,
      realm: realm,
      client_id: client_id
    }
  end

  defp encode_id_token(%{
         key: %{key: key},
         id_token: id_token,
         home_account_id: home_account_id,
         environment: environment,
         realm: realm,
         client_id: client_id
       }) do
    {key,
     %{
       "credential_type" => "IdToken",
       "secret" => id_token,
       "home_account_id" => home_account_id,
       "environment" => environment,
       "realm" => realm,
       "client_id" => client_id
     }}
  end

  defp decode_app_metadata(
         {key,
          %{
            "client_id" => client_id,
            "environment" => environment,
            "family_id" => family_id
          }}
       ) do
    %{
      key: key,
      client_id: client_id,
      environment: environment,
      family_id: family_id
    }
  end

  defp encode_app_metadata(%{
         key: key,
         client_id: client_id,
         environment: environment,
         family_id: family_id
       }) do
    {key,
     %{
       "client_id" => client_id,
       "environment" => environment,
       "family_id" => family_id
     }}
  end

  def decode_file(%{
        "AccessToken" => access_tokens,
        "Account" => accounts,
        "IdToken" => id_tokens,
        "RefreshToken" => refresh_tokens,
        "AppMetadata" => app_metadata
      }) do
    %__MODULE__{
      access_tokens: access_tokens |> Enum.map(&decode_access_token/1),
      accounts: accounts |> Enum.map(&decode_account/1),
      id_tokens: id_tokens |> Enum.map(&decode_id_token/1),
      refresh_tokens: refresh_tokens |> Enum.map(&decode_refresh_token/1),
      app_metadata: app_metadata |> Enum.map(&decode_app_metadata/1)
    }
  end

  def encode_file(%__MODULE__{
        access_tokens: access_tokens,
        accounts: accounts,
        id_tokens: id_tokens,
        refresh_tokens: refresh_tokens,
        app_metadata: app_metadata
      }) do
    %{
      "AccessToken" => access_tokens |> Map.new(&encode_access_token/1),
      "Account" => accounts |> Map.new(&encode_account/1),
      "IdToken" => id_tokens |> Map.new(&encode_id_token/1),
      "RefreshToken" => refresh_tokens |> Map.new(&encode_refresh_token/1),
      "AppMetadata" => app_metadata |> Map.new(&encode_app_metadata/1)
    }
  end

  defp epoch_string_to_datetime(epoch_string) when is_binary(epoch_string) do
    with {epoch_int, ""} <- Integer.parse(epoch_string, 10),
         {:ok, timestamp} <- DateTime.from_unix(epoch_int, :second) do
      timestamp
    else
      s -> {:error, s}
    end
  end

  defp datetime_to_epoch_string(timestamp) do
    timestamp
    |> DateTime.to_unix(:second)
    |> Integer.to_string()
  end

  @key_regex ~r/^(?<oid>[0-9A-Fa-f]{8}[-]?([0-9A-Fa-f]{4}[-]?){3}[0-9A-Fa-f]{12})\.(?<tid>[0-9A-Fa-f]{8}[-]?([0-9A-Fa-f]{4}[-]?){3}[0-9A-Fa-f]{12})-(?<domain>[^-]+)-(?<type>[^-]+)-(?<app_id>[0-9A-Fa-f]{8}[-]?([0-9A-Fa-f]{4}[-]?){3}[0-9A-Fa-f]{12})-(?<realm>organizations|[0-9A-Fa-f]{8}[-]?([0-9A-Fa-f]{4}[-]?){3}[0-9A-Fa-f]{12})?-(?<scope>.*)$/

  defp parse_key(key) do
    %{
      "app_id" => app_id,
      "domain" => domain,
      "oid" => oid,
      "realm" => realm,
      "scope" => scope,
      "tid" => tid,
      "type" => type
    } = Regex.named_captures(@key_regex, key)

    %{
      key: key,
      app_id: app_id,
      domain: domain,
      oid: oid,
      realm: realm,
      scope: scope,
      tid: tid,
      type: type
    }
  end

  def remove_expired_access_tokens(msal_contents),
    do: remove_expired_access_tokens(msal_contents, DateTime.utc_now())

  def remove_expired_access_tokens(%__MODULE__{access_tokens: tokens} = msal_contents, now) do
    still_valid_tokens =
      tokens
      |> Enum.filter(fn token -> DateTime.compare(now, token.expires_on) == :lt end)

    %__MODULE__{msal_contents | access_tokens: still_valid_tokens}
  end

  # def remove_expired_id_tokens(msal_contents),
  #   do: remove_expired_id_tokens(msal_contents, DateTime.utc_now())
  #
  # def remove_expired_id_tokens(%__MODULE__{id_tokens: tokens} = msal_contents, now) do
  #   still_valid_tokens =
  #     tokens
  #     |> Enum.filter(fn token -> DateTime.compare(now, token.expires_on) == :lt end)
  #
  #   %__MODULE__{msal_contents | id_tokens: still_valid_tokens}
  # end

  def get_refresh_token(%__MODULE__{} = msal_contents, %Entra.ClientInfo{} = client_info) do
    home_account_id = Entra.ClientInfo.to_home_account_id(client_info)

    matching_refresh_tokens =
      msal_contents.refresh_tokens
      |> Enum.filter(fn %{home_account_id: id} -> home_account_id == id end)

    case matching_refresh_tokens do
      [refresh_token] -> {:ok, refresh_token}
      [] -> :no_found
    end
  end

  def get_refresh_token_by_username_and_audience(%__MODULE__{} = state, username, audience) do
    matching_tokens = 
      state
      |> refresh_tokens()
      |> get_in([username])
      |> Enum.filter(&String.contains?(&1.target, audience))
    case matching_tokens do
      [refresh_token] -> {:ok, refresh_token}
      [] -> :not_found
      _ -> {:error, "Multiple matching refresh tokens found"}
    end
  end

  defp update_access_token(state, key, access_token, iat, exp) do
    state
    |> Map.update!(:access_tokens, &(
    Enum.map(&1, fn 
        t = %{key: %{key: ^key}} -> %{t | access_token: access_token, cached_at: iat, expires_on: exp, extended_expires_on: exp}
        t -> t
      end)))
  end

  defp update_refresh_token(state, key, refresh_token, iat) do
    state
    |> Map.update!(:refresh_tokens, &(
    Enum.map(&1, fn 
        t = %{key: %{key: ^key}} -> %{t | refresh_token: refresh_token, last_modification_time: iat }
        t -> t
      end)))
  end

  defp update_id_token(state, key, id_token) do
    state
    |> Map.update!(:id_tokens, &(
    Enum.map(&1, fn 
        t = %{key: %{key: ^key}} -> %{t | id_token: id_token }
        t -> t
      end)))
  end

  def update_state_with_token_response(state, token_response) do
    {:ok, %{ "appid" => app_id, "oid" => oid, "tid" => tid, "iat" => iat,  "exp" => exp }} = 
      token_response["access_token"]
      |> Joken.peek_claims()
    iat = DateTime.from_unix!(iat)
    exp = DateTime.from_unix!(exp)

    key = fn (token_type, realm_handling) ->      
      case realm_handling do
        :tid_is_realm -> "#{oid}.#{tid}-login.microsoftonline.com-#{token_type}-#{app_id}-#{tid}-#{token_response["scope"]}"
        :empty_realm -> "#{oid}.#{tid}-login.microsoftonline.com-#{token_type}-#{app_id}--#{token_response["scope"]}"
      end
    end

    state
    |> update_id_token(key.("idtoken", :tid_is_realm), token_response["id_token"])
    |> update_access_token(key.("accesstoken", :tid_is_realm), token_response["access_token"], iat, exp)
    |> update_refresh_token(key.("refreshtoken", :empty_realm), token_response["refresh_token"], iat)
  end

  def update_refresh_token(
        %__MODULE__{} = msal_contents,
        %{key: new_key} = new_refresh_token
      ) do
    case msal_contents.refresh_tokens |> Enum.find_index(fn %{key: old_key} -> old_key == new_key end) do
      nil ->
        msal_contents

      index ->
        %{
          msal_contents
          | refresh_tokens: msal_contents.refresh_tokens |> List.replace_at(index, new_refresh_token)
        }
    end
  end

  def refresh_tokens(%__MODULE__{} = state) do
    %{accounts: accounts, refresh_tokens: refresh_tokens} = state

    accounts_by_home_account_id =
      accounts
      |> Enum.map(fn account = %{home_account_id: home_account_id} ->
        {home_account_id, account}
      end)
      |> Map.new()

    #
    # Augment the refresh_token with the username
    #
    refresh_tokens =
      refresh_tokens
      |> Enum.map(fn refresh_token = %{home_account_id: home_account_id} ->
        {:ok, account} =
          accounts_by_home_account_id
          |> Map.fetch(home_account_id)

        refresh_token =
          refresh_token
          |> Map.put(:username, account.username)

        {account.username, refresh_token}
      end)
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

    refresh_tokens
  end

  def msal_token_cache_dir() do
    [System.user_home!(), ".azure"]
    |> Path.join()
    |> Path.absname()
  end

  def msal_token_cache_file() do
    filename =
      case :os.type() do
        {:win32, _} -> "msal_token_cache.bin"
        _ -> "msal_token_cache.json"
      end

    Path.absname(Path.join([msal_token_cache_dir(), filename]))
  end

  defp encryption_and_json_settings() do
    case :os.type() do
      {:win32, _} ->
        # On Windows, the file is encrypted with DPAPI
        {&Windows.API.DataProtection.unwrap/1, &Windows.API.DataProtection.wrap/1, []}

      _ ->
        # On Linux and Mac, the JSON file is not encrypted
        {&Function.identity/1, &Function.identity/1, [pretty: true]}
    end
  end

  def load_pure_contents_from_user_home() do
    with filename = msal_token_cache_file(),
         {decrypt, _encrypt, _json_encode_opts} <- encryption_and_json_settings(),
         {:ok, contents} <- File.read(filename),
         contents <- contents |> decrypt.(),
         {:ok, contents} <- Jsonrs.decode(contents) do
      {:ok, contents}
    else
      err -> err
    end
  end

  def load_from_user_home() do
    with {:ok, contents} <- load_pure_contents_from_user_home(),
         contents <- contents |> decode_file() do
      {:ok, contents}
    else
      err -> err
    end
  end

  def write_plaintext_to_user_home(contents) when is_binary(contents) do
    with filename = msal_token_cache_file(),
         {_decrypt, encrypt, _json} <- encryption_and_json_settings(),
         contents <- contents |> encrypt.() do
      File.write(filename, contents)
    else
      err -> err
    end
  end

  def write_to_user_home(%__MODULE__{} = contents) do
    with {_decrypt, _encrypt, json_encode_opts} <- encryption_and_json_settings(),
         {:ok, byte_contents} <- contents |> encode_file() |> Jsonrs.encode(json_encode_opts),
         :ok <- write_plaintext_to_user_home(byte_contents) do
      contents
    else
      err -> err
    end
  end
end
