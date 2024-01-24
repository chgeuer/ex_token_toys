defmodule Convert do
    def parse!("true", :bool), do: true
    def parse!("false", :bool), do: false
    def parse!(true, :bool), do: true
    def parse!(false, :bool), do: false
    def parse!(num, :int) when is_integer(num), do: num
  
    def parse!(str, :int) when is_binary(str) do
      {i, ""} = Integer.parse(str)
      i
    end
  
    def parse!(str, :float) when is_binary(str) do
      {i, ""} = Float.parse(str)
      i
    end
  
    def parse!(str, :duration) when is_binary(str) do
      str
      |> String.split(":")
      |> parse!(:duration)
    end
  
    def parse!([d, h, m, s], :duration) do
      d = d |> parse!(:int)
      h = h |> parse!(:int)
      m = m |> parse!(:int)
      s = s |> parse!(:float)
  
      total_seconds = d * 24 * 60 * 60 + h * 60 * 60 + m * 60 + s
  
      {:second, total_seconds}
    end
  
    def parse!([h, m, s], :duration) do
      h = h |> parse!(:int)
      m = m |> parse!(:int)
      s = s |> parse!(:int)
  
      total_seconds = h * 60 * 60 + m * 60 + s
  
      {:second, total_seconds}
    end
  end