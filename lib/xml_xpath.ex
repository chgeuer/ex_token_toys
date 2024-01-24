defmodule XMLXPath do
  require Record
  
  def keyword_list_to_namespace(kwl) do
      kwl
      |> Enum.map(fn {k, v} -> {Atom.to_charlist(k), String.to_charlist(v)} end)
      |> (fn map -> [namespace: map] end).()
    end
  
    def xpath(document, xpath, namespaces) do
      xml_str = document |> String.to_charlist()
      {doc, ~c[]} = :xmerl_scan.string(xml_str, namespace_conformant: true)
      :xmerl_xpath.string(String.to_charlist(xpath), doc, keyword_list_to_namespace(namespaces))
    end
  
    for {name, fields} <- Record.extract_all(from_lib: "xmerl/include/xmerl.hrl") do
      Record.defrecordp(name, fields)
    end
  
    def text(list) do
      for xmlText(value: value) <- list do
        List.to_string(value)
      end
    end
  end