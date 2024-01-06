defmodule Req.Fiddler do
  def fiddler_req(proxy_ip, proxy_port, proxy_cert) do
    mint_connect_options = [
      proxy: {:http, proxy_ip, proxy_port, []},
      # https://hexdocs.pm/mint/Mint.HTTP.html#connect/4-transport-options
      transport_opts: [
        # openssl x509 -inform der -in FiddlerRoot.cer -out FiddlerRoot.pem
        cacertfile: proxy_cert
      ]
    ]

    Req.new(connect_options: mint_connect_options)
  end
end
