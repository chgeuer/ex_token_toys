defmodule MsalTokenCacheKey do
  defstruct [:key, :oid, :tid, :domain, :type, :app_id, :realm, :scope]

  # oid-tid-domain-type-app_id-realm-scope
  @key_regex ~r/^(?<oid>[0-9A-Fa-f]{8}[-]?([0-9A-Fa-f]{4}[-]?){3}[0-9A-Fa-f]{12})\.(?<tid>[0-9A-Fa-f]{8}[-]?([0-9A-Fa-f]{4}[-]?){3}[0-9A-Fa-f]{12})-(?<domain>[^-]+)-(?<type>[^-]+)-(?<app_id>[0-9A-Fa-f]{8}[-]?([0-9A-Fa-f]{4}[-]?){3}[0-9A-Fa-f]{12})-(?<realm>organizations|[0-9A-Fa-f]{8}[-]?([0-9A-Fa-f]{4}[-]?){3}[0-9A-Fa-f]{12})?-(?<scope>.*)$/

  @domain "login.microsoftonline.com"

  # @AzurePortal "c44b4083-3bb0-49c1-b47d-974e53cbdf3c"
  # @MicrosoftAzureCLI "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
  # @MicrosoftAzurePowerShell "1950a258-227b-4e31-a9cf-717495945fc2"
  # @MicrosoftGraph "00000003-0000-0000-c000-000000000000"
  # @WindowsAzureActiveDirectory "00000002-0000-0000-c000-000000000000"
  # @WindowsAzureServiceManagementAPI "797f4846-ba00-4fd7-ba43-dac1f8f63013"

  def parse(key) do
    %{
      "oid" => oid,
      "tid" => tid,
      "domain" => domain,
      "type" => type,
      "app_id" => app_id,
      "realm" => realm,
      "scope" => scope
    } = Regex.named_captures(@key_regex, key)

    %__MODULE__{
      key: key,
      oid: oid,
      tid: tid,
      domain: domain,
      type: type,
      app_id: app_id,
      realm: realm,
      scope: scope
    }
  end

  def key_str(oid, tid, token_type, app_id, realm, scope) do
    "#{oid}.#{tid}-#{@domain}-#{token_type}-#{app_id}-#{realm}-#{scope}"
  end
end
