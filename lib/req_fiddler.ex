defmodule Req.Fiddler do

  @nimble_options_definition [
    proxy_ip: [
      type: :string,
      required: true,
    ], 
    proxy_port: [
      type: :non_neg_integer,
      default: 8888
    ],
    proxy_cert: [
      type: :string,
      required: true,
    ]
  ]

  defp fiddler_connect_options(fiddler_options) do
    {:ok, [proxy_ip: proxy_ip, proxy_port: proxy_port, proxy_cert: proxy_cert]} = 
      NimbleOptions.validate(fiddler_options, @nimble_options_definition)

    [
      proxy: {:http, proxy_ip, proxy_port, []},
      # https://hexdocs.pm/mint/Mint.HTTP.html#connect/4-transport-options
      transport_opts: [
        # openssl x509 -inform der -in FiddlerRoot.cer -out FiddlerRoot.pem
        cacertfile: proxy_cert
      ]
    ]
  end

  def attach_fiddler(req, fiddler_options \\ []) do
    req
    |> Req.merge(connect_options: fiddler_connect_options(fiddler_options))
  end

  def add_proxy_on_beam(req) do
    attach_fiddler(req, [proxy_ip: "127.0.0.1", proxy_port: 8888, 
      proxy_cert: Path.join([System.user_home!(), "FiddlerRoot.pem"])])
  end
end
