defmodule MarkdownHelper do

  defp as_str(x) when is_binary(x), do: x
  defp as_str(x), do: "#{inspect{x}}"
    
    @doc ~S"""
    Formats a row in a Markdown table.
  
    ## Examples
  
      iex> MarkdownHelper.row(["a", "b"])
      "| a | b |"
    """
    def row(data) do
      data
      |> Enum.map(&as_str/1)
      |> Enum.join(" | ")
      |> (fn x -> "| #{x} |" end).()
    end
  
    @doc ~S"""
    Formats a separator row in a Markdown table.
  
    ## Examples
  
      iex> MarkdownHelper.sep(["a", "b"])
      "| --- | --- |"
    """
    def sep(indexes) do
      1..Enum.count(indexes)
      |> Enum.map(fn _ -> "---" end)
      |> row()
    end
  
    @doc ~S"""
    Picks items in given indexed order.
  
    ## Examples
  
      iex> MarkdownHelper.table_body(
      ...>  [
      ...>      %{"a" => "a1", "b" => "b1"}, 
      ...>      %{"a" => "a2", "b" => "b2"}
      ...>  ], 
      ...>  ~w(a b))
      
      "| a1 | b1 |\n| a2 | b2 |"
    """
    def table_body(items, indexes) do
      for item <- items do
        for index <- indexes do
          item |> get_in([index])
        end
      end
      |> Enum.map(&row/1)
    end
  
    @doc ~S"""
    Formats a Markdown table in given indexed order.
  
    ## Examples
  
      iex> [
      ...>   %{"a" => "a1", "b" => "b1"}, 
      ...>   %{"a" => "a2", "b" => "b2"}
      ...> ] |> MarkdownHelper.create_markdown_table(~w(a b))
      "| a | b |\n| --- | --- |\n| a1 | b1 |\n| a2 | b2 |"

      iex> [
      ...>   %{"a" => "a1", "b" => "b1"}, 
      ...>   %{"a" => "a2", "b" => "b2"}
      ...> ] |> MarkdownHelper.create_markdown_table(~w(a b), ["Column A", "Column B"])
      "| Column A | Column B |\n| --- | --- |\n| a1 | b1 |\n| a2 | b2 |"
    """
    def create_markdown_table(items, indexes), do: create_markdown_table(items, indexes, indexes)
    def create_markdown_table(items, indexes, column_names) when is_list(items) and is_list(indexes) and is_list(column_names) do
      [row(column_names) | [sep(indexes) | table_body(items, indexes)]]
      |> Enum.join("\n")
    end
  end