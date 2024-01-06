defmodule Entra.ClientInfo do
  @type t :: %__MODULE__{user_object_id: String.t(), user_tenant_tid: String.t()}
  defstruct [:user_object_id, :user_tenant_tid]

  @doc ~S"""
  Handle id

  ## Examples

    iex> "eyJ1aWQiOiJlNjcyM2Y3NS0wMzMyLTRkZDgtYjMzNi05NmJmY2M4MTAwMDYiLCJ1dGlkIjoiNzJmOTg4YmYtODZmMS00MWFmLTkxYWItMmQ3Y2QwMTFkYjQ3In0"
    ...> |> Entra.ClientInfo.from_base64()
    ...> |> Entra.ClientInfo.to_base64()
    ...> |> Entra.ClientInfo.from_base64()
    ...> |> Entra.ClientInfo.to_home_account_id()
    ...> |> Entra.ClientInfo.from_home_account_id()
    %Entra.ClientInfo{
      user_object_id: "e6723f75-0332-4dd8-b336-96bfcc810006",
      user_tenant_tid: "72f988bf-86f1-41af-91ab-2d7cd011db47"
    }

    iex> Entra.ClientInfo.new(
    ...>      "f2691ff1-6e10-4969-a550-d25f99ab7c8e",
    ...>      "a78648ba-0157-4003-be64-98bd2b3ec54a")
    %Entra.ClientInfo{
      user_object_id: "f2691ff1-6e10-4969-a550-d25f99ab7c8e",
      user_tenant_tid: "a78648ba-0157-4003-be64-98bd2b3ec54a"
    }

  """
  def new(user_object_id, user_tenant_tid) do
    %__MODULE__{user_object_id: user_object_id, user_tenant_tid: user_tenant_tid}
  end

  @doc ~S"""
  Parse a client_info from base64-encodede client_info claim.

  ## Examples

    iex> "eyJ1aWQiOiJmMjY5MWZmMS02ZTEwLTQ5NjktYTU1MC1kMjVmOTlhYjdjOGUiLCJ1dGlkIjoiYTc4NjQ4YmEtMDE1Ny00MDAzLWJlNjQtOThiZDJiM2VjNTRhIn0"
    ...> |> Entra.ClientInfo.from_base64()
    ...>
    %Entra.ClientInfo{
       user_object_id: "f2691ff1-6e10-4969-a550-d25f99ab7c8e",
       user_tenant_tid: "a78648ba-0157-4003-be64-98bd2b3ec54a"
    }
  """
  def from_base64(client_info_claim) when is_binary(client_info_claim) do
    %{"uid" => user_object_id, "utid" => user_tenant_tid} =
      client_info_claim
      |> Base.decode64!(padding: false)
      |> Jsonrs.decode!()

    %__MODULE__{user_object_id: user_object_id, user_tenant_tid: user_tenant_tid}
  end

  @doc ~S"""
  Convert to base64-encoded client_info claim value.

  ## Examples

    iex> Entra.ClientInfo.new(
    ...>   "f2691ff1-6e10-4969-a550-d25f99ab7c8e",
    ...>   "a78648ba-0157-4003-be64-98bd2b3ec54a")
    ...> |> Entra.ClientInfo.to_base64()
    "eyJ1aWQiOiJmMjY5MWZmMS02ZTEwLTQ5NjktYTU1MC1kMjVmOTlhYjdjOGUiLCJ1dGlkIjoiYTc4NjQ4YmEtMDE1Ny00MDAzLWJlNjQtOThiZDJiM2VjNTRhIn0"

  """
  def to_base64(%__MODULE__{user_object_id: user_object_id, user_tenant_tid: user_tenant_tid}) do
    %{"uid" => user_object_id, "utid" => user_tenant_tid}
    |> Jsonrs.encode!()
    |> Base.encode64(padding: false)
  end

  def from_home_account_id(home_account_id) when is_binary(home_account_id) do
    [user_object_id, user_tenant_tid] = home_account_id |> String.split(".")

    %__MODULE__{user_object_id: user_object_id, user_tenant_tid: user_tenant_tid}
  end

  @doc ~S"""
  Convert to base64-encoded client_info claim value.

  ## Examples

    iex> Entra.ClientInfo.new(
    ...>      "f2691ff1-6e10-4969-a550-d25f99ab7c8e",
    ...>      "a78648ba-0157-4003-be64-98bd2b3ec54a")
    ...> |> Entra.ClientInfo.to_home_account_id()
    "f2691ff1-6e10-4969-a550-d25f99ab7c8e.a78648ba-0157-4003-be64-98bd2b3ec54a"
  """
  def to_home_account_id(%__MODULE__{} = ci) do
    "#{ci.user_object_id}.#{ci.user_tenant_tid}"
  end

  def to_routing_header(%__MODULE__{
        user_object_id: user_object_id,
        user_tenant_tid: user_tenant_tid
      }) do
    {"X-AnchorMailbox", "oid:#{user_object_id}@#{user_tenant_tid}"}
  end
end
