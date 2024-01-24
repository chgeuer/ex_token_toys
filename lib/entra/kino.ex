defmodule Entra.Kino do
  def render_domain_as_markdown_text(domain) do
    [tenant_id, domains] =
      Task.await_many([
        Task.async(fn -> Entra.Discovery.get_tenant_id_for_domain(domain) end),
        Task.async(fn -> Entra.Discovery.get_all_domains(domain) end)
      ])

    case [tenant_id, domains] do
      [{:ok, tenant_id}, {:ok, domains}] ->
        """
        # Domains for Entra tenant `#{tenant_id}` (`#{domain}`)

        #{domains |> Enum.map(fn d -> "- `#{d}`\n" end)}
        """

      _ ->
        """
        # Error retrieving information for `#{domain}`
        """
    end
  end
end
