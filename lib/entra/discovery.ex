defmodule Entra.Discovery do
  def request_body_xml(domain) do
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
end
