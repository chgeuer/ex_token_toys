defmodule Entra.Discovery do
  defp request_body_xml(domain) do
    """
    <?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
     <soap:Header xmlns:a="http://www.w3.org/2005/08/addressing">
      <a:Action soap:mustUnderstand="1">http://schemas.microsoft.com/exchange/2010/Autodiscover/Autodiscover/GetFederationInformation</a:Action>
      <a:To soap:mustUnderstand="1">https://autodiscover-s.outlook.com/autodiscover/autodiscover.svc</a:To>
      <a:ReplyTo>
       <a:Address>http://www.w3.org/2005/08/addressing/anonymous</a:Address>
      </a:ReplyTo>
     </soap:Header>
     <soap:Body>
      <GetFederationInformationRequestMessage xmlns="http://schemas.microsoft.com/exchange/2010/Autodiscover">
       <Request>
         <Domain>#{domain}</Domain>
       </Request>
      </GetFederationInformationRequestMessage>
     </soap:Body>
    </soap:Envelope>
    """
  end

  def get_all_domains(domain) do
    try do
      %Req.Response{
        status: 200,
        body: xml_response
      } =
        Req.new()
        |> Req.Request.put_header("Content-Type", "text/xml; charset=utf-8")
        |> Req.Request.put_header(
          "SOAPAction",
          "\"http://schemas.microsoft.com/exchange/2010/Autodiscover/Autodiscover/GetFederationInformation\""
        )
        |> Req.post!(
          url: "https://autodiscover-s.outlook.com/autodiscover/autodiscover.svc",
          body: request_body_xml(domain)
        )

      [error] =
        xml_response
        |> XMLXPath.xpath("//discover:ErrorCode/text()",
          discover: "http://schemas.microsoft.com/exchange/2010/Autodiscover"
        )
        |> XMLXPath.text()

      case error do
        "InvalidDomain" ->
          {:error, :invalid_domain}

        "NoError" ->
          domain_list =
            xml_response
            |> XMLXPath.xpath("//discover:Domain/text()",
              discover: "http://schemas.microsoft.com/exchange/2010/Autodiscover"
            )
            |> XMLXPath.text()

          {:ok, domain_list}
      end
    rescue
      e -> {:error, e}
    end
  end

  def get_tenant_id_for_domain(domain) do
    try do
      %Req.Response{
        status: status,
        body: body
      } =
        Req.new()
        |> Req.get!(
          url: "https://login.microsoftonline.com/#{domain}/.well-known/openid-configuration"
        )

      case status do
        200 ->
          %{"issuer" => "https://sts.windows.net/" <> tenant_id} = body

          tenant_id = tenant_id |> String.trim_trailing("/")

          {:ok, tenant_id}

        400 ->
          {:error, :bad_request}

        404 ->
          {:error, :not_found}

        error ->
          {:error, "HTTP Status code #{error}"}
      end
    rescue
      e -> {:error, e}
    end
  end

  def find_tenantInformation_by_tenant_id(%Req.Request{} = graph_client, tenant_id) do
    response = graph_client
    |> Req.get!(
      url:
        "https://graph.microsoft.com/v1.0/tenantRelationships/findTenantInformationByTenantId(tenantId='#{tenant_id}')"
    )

    case response do
      %Req.Response{status: 404} -> {:error, :not_found}
      %Req.Response{
        status: 200,
        body: %{
          "@odata.context" =>
            "https://graph.microsoft.com/v1.0/$metadata#microsoft.graph.tenantInformation",
          "defaultDomainName" => default_domain_name,
          "displayName" => display_name,
          "federationBrandName" => federation_brand_name,
          "tenantId" => ^tenant_id
        }
      } -> 
        {:ok, %{
          tenant_id: tenant_id,
          default_domain_name: default_domain_name,
          display_name: display_name,
          federation_brand_name: federation_brand_name
        } }
      %Req.Response{status: status, body: body} -> {:error, %{ status: status, body: body}}
    end
  end

  def get_default_domain_name(graph_client, tenant_id) do
    with {:ok, response } <- graph_client |> find_tenantInformation_by_tenant_id(tenant_id) do
      { :ok, response |> get_in([:default_domain_name]) }
    end
  end

  defp audience(:graph), do: {"management.core.windows.net", "https://graph.microsoft.com//.default offline_access openid profile"} 
  defp audience(:arm), do: {"management.core.windows.net", "https://management.core.windows.net//.default offline_access openid profile"}
  defp audience(:storage), do: {"management.core.windows.net", "https://storage.azure.com//.default offline_access openid profile" }
  defp audience(:keyvault), do: {"management.core.windows.net", "https://vault.azure.net//.default offline_access openid profile" }
  defp audience(:cxobserve), do: {"7d401da2-e710-4600-be01-f048d5e307fa", "api://7d401da2-e710-4600-be01-f048d5e307fa/user_impersonation offline_access openid profile"}

  defp post_request_body(:cxobserve, refresh_token, scope) do
    post_request_body(:default, refresh_token, scope)
    |> put_in([:form, :redirect_uri], "https://cxp.azure.com/cxobserve//auth.html")
  end
  defp post_request_body(_aud, refresh_token, scope) do
    [
      url: "https://login.microsoftonline.com/common/oauth2/v2.0/token",
      form: [
        grant_type: :refresh_token,
        client_info: 1,
        scope: scope,
        client_id: refresh_token.client_id,
        refresh_token: refresh_token.refresh_token
      ]
    ]
  end

  defp add_token_request_headers(req, :cxobserve) do
    req
    |> Req.Request.put_headers([
      {"Referer", "https://cxp.azure.com/"}, 
      {"Origin", "https://cxp.azure.com"}
    ])
  end
  defp add_token_request_headers(req, _aud), do: req

  def fetch_token(username, aud, req \\ Req.new()) do
    state = MsalTokenCache.get_state()

    {domain, scope} = audience(aud)

    {:ok, refresh_token} =
      state
      |> MsalTokenCacheParser.get_refresh_token_by_username_and_audience(username, domain)

    %Req.Response{
      status: 200,
      body: %{
        "access_token" => access_token,
        "expires_in" => expires_in,
        "client_info" => client_info,
        "id_token" => id_token,
        "refresh_token" => refresh_token,
        "scope" => scope,
        "token_type" => "Bearer"
      }
    } = req
        |> add_token_request_headers(aud)
        |> Req.post!(post_request_body(aud, refresh_token, scope))

    %{
      "access_token" => access_token,
      "expires_in" => expires_in,
      "client_info" => client_info,
      "id_token" => id_token,
      "refresh_token" => refresh_token,
      "scope" => scope,
      "token_type" => "Bearer"
    }
  end

  def get_client(username, aud, req \\ Req.new()) when is_atom(aud) do
    %{
      "access_token" => access_token,
      # "expires_in" => expires_in,
      # "client_info" => client_info,
      # "id_token" => id_token,
      # "refresh_token" => refresh_token,
      # "scope" => scope,
      # "token_type" => "Bearer"
    } = fetch_token(username, aud, req)
    
    req
    |> Req.Request.put_header("Authorization", "Bearer #{access_token}")
  end

  defp verified_domain_to_struct(%{
         "capabilities" => capabilities,
         "isDefault" => is_default,
         "isInitial" => is_initial,
         "name" => name,
         "type" => type
       }) do
    %{
      capabilities: capabilities |> String.split(", "),
      is_default: is_default,
      is_initial: is_initial,
      name: name,
      type: type
    }
  end

  def get_verified_domains(_, "00000000-0000-0000-0000-000000000000"), do: {:error, "Tenant ID is not set"}
  def get_verified_domains(graph_req, tenant_id) do
    graph_response =
      graph_req
      |> Req.get!(url: "https://graph.microsoft.com/v1.0/organization/#{tenant_id}")

    case graph_response do
      %Req.Response{
        status: 200,
        body: %{
          "id" => ^tenant_id,
          "verifiedDomains" => verified_domains
        }
      } ->
        verified_domains
        |> Enum.map(&verified_domain_to_struct/1)

        {:ok, verified_domains}

      %Req.Response{status: 404} ->
        {:error, :not_found}

      %Req.Response{body: body} ->
        {:error, body}
    end
  end

  def get_default_domain(verified_domains) do
    verified_domains
    |> Enum.filter(fn domain -> domain.is_default end)
    |> List.first()
    |> get_in([:name])
  end

  def crack_id_token(id_token) do
    id_token
    |> JOSE.JWT.peek()
    |> (fn %JOSE.JWT{fields: fields} -> fields end).()
    |> (fn %{
             "sub" => sub,
             "tid" => tid,
             "aud" => aud,
             "exp" => exp,
             "preferred_username" => preferred_username
           } ->
          %{
            sub: sub,
            tid: tid,
            aud: aud,
            username: preferred_username,
            exp: DateTime.to_iso8601(DateTime.from_unix!(exp, :second))
          }
        end).()
  end

  def crack_access_token(access_token) do
    access_token
    |> JOSE.JWT.peek()
    |> (fn %JOSE.JWT{fields: fields} -> fields end).()
    |> (fn %{
             "sub" => sub,
             "tid" => tid,
             "aud" => aud,
             "exp" => exp,
             "unique_name" => unique_name
           } ->
          %{
            sub: sub,
            tid: tid,
            aud: aud,
            username: unique_name,
            exp: DateTime.to_iso8601(DateTime.from_unix!(exp, :second))
          }
        end).()
  end
end
