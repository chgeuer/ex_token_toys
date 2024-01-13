defmodule DummyCode do
  require Logger

  defp utc_now_plus_seconds(seconds) do
    {:ok, time} =
      DateTime.utc_now()
      |> DateTime.to_unix(:second)
      |> Kernel.+(seconds)
      |> DateTime.from_unix(:second)

    time
  end

  def hello() do
    # chgeuer@microsoft.com
    user_id = "e6723f75-0332-4dd8-b336-96bfcc810006"
    # microsoft.microsoftonline.com
    tenant_id = "72f988bf-86f1-41af-91ab-2d7cd011db47"

    client_info = Entra.ClientInfo.new(user_id, tenant_id)

    {:ok, old_refresh_token} =
      MsalTokenCache.get_state()
      |> MsalTokenCacheParser.get_refresh_token(client_info)

    req = Req.new()

    %Req.Response{
      status: 200,
      headers: %{
        "x-ms-request-id" => [_x_ms_request_id],
        "x-ms-ests-server" => [x_ms_ests_server]
      },
      body: %{
        "access_token" => access_token,
        "client_info" => client_info,
        "expires_in" => expires_in,
        "ext_expires_in" => ext_expires_in,
        "foci" => "1",
        "id_token" => id_token,
        "refresh_token" => refresh_token,
        "scope" => scope,
        "token_type" => "Bearer"
      }
    } =
      req
      |> Req.post!(
        url: "https://login.microsoftonline.com/common/oauth2/v2.0/token",
        form: [
          grant_type: :refresh_token,
          client_info: 1,
          # refresh_token.target,
          scope: "https://management.core.windows.net//.default offline_access openid profile",
          client_id: old_refresh_token.client_id,
          refresh_token: old_refresh_token.refresh_token
        ]
      )

    Logger.info("got refresh token from server \"#{x_ms_ests_server}\"")

    {:ok,
     %{
       scope: scope,
       client_info: Entra.ClientInfo.from_base64(client_info),
       access_token: access_token,
       id_token: id_token,
       refresh_token: refresh_token,
       expires_on: utc_now_plus_seconds(expires_in),
       ext_expires_on: utc_now_plus_seconds(ext_expires_in)
     }}
  end
end
