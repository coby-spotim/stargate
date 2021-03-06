defmodule Starship.Reactor.Websocket.Handshake do
  @moduledoc """
  Functions for handling a websocket handshake from `Starship.Reactor.Websocket`.
  """

  alias Starship.Reactor.Conn
  import Starship.Reactor.Response, only: [build_response: 4]

  @ws_guid "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

  @spec rejected_handshake(map) :: map
  def rejected_handshake(config) do
    response_io_list = build_response(400, [{"Connection", "close"}], "", :"HTTP/1.1")
    :ok = config.transport.send(config.socket, response_io_list)
    config
  end

  @spec successful_handshake(Conn.t(), map, map) :: map
  def successful_handshake(conn, config, opts) do
    {headers, should_compress} = build_handshake_reply_headers(conn.headers, opts)

    config =
      if should_compress do
        compress_handshake(config, opts)
      else
        config
      end

    handshake_response =
      <<"HTTP/1.1 101 Switching Protocols\r\n"::binary,
        Enum.reduce(headers, "", fn {k, v}, a -> a <> "#{k}: #{v}\r\n" end)::binary, "\r\n">>

    :ok = config.transport.send(config.socket, handshake_response)
    config
  end

  @spec build_handshake_reply_headers(Conn.headers(), map) :: {Conn.headers(), boolean}
  def build_handshake_reply_headers(headers, opts) do
    {_, ws_key} = List.keyfind(headers, "sec-websocket-key", 0)
    ws_ext = extract_websocket_extensions(headers)

    extra_headers =
      if opts[:compress] != nil and ws_ext["permessage-deflate"] != nil do
        [{"Sec-WebSocket-Extensions", "permessage-deflate"}]
      else
        []
      end

    inject_headers = Map.get(opts, :inject_headers, [])

    reply_headers =
      [
        {"Upgrade", "websocket"},
        {"Connection", "Upgrade"},
        {"Sec-WebSocket-Accept", :base64.encode(:crypto.hash(:sha, <<ws_key::binary, @ws_guid>>))}
      ] ++ extra_headers ++ inject_headers

    {reply_headers, length(extra_headers) > 0}
  end

  @spec extract_websocket_extensions(Conn.headers()) :: map
  def extract_websocket_extensions(headers) do
    headers
    |> List.keyfind("sec-websocket-extensions", 0)
    |> parse_websocket_extensions
  end

  @spec parse_websocket_extensions({any, binary}) :: map
  defp parse_websocket_extensions({_, ws_ext}) do
    ws_ext = String.replace(ws_ext, " ", "")
    ws_ext = String.split(ws_ext, ",", trim: true)

    Enum.reduce(ws_ext, %{}, fn ext, acc ->
      case String.split(ext, ";", trim: true) do
        [h | [] = _t] -> Map.put(acc, h, "")
        [h | t] -> Map.put(acc, h, t)
        _ -> acc
      end
    end)
  end

  defp parse_websocket_extensions(_), do: %{}

  @spec compress_handshake(map, map) :: map
  def compress_handshake(config, opts) do
    inflate_zlib = :zlib.open()
    :zlib.inflateInit(inflate_zlib, -15)

    compress = Map.get(opts, :compress, %{})
    level = Map.get(compress, :level, 1)
    mem_level = Map.get(compress, :mem_level, 8)
    window_bits = Map.get(compress, :window_bits, 15)
    strategy = Map.get(compress, :strategy, :default)

    deflate_zlib = :zlib.open()
    :zlib.deflateInit(deflate_zlib, level, :deflated, -window_bits, mem_level, strategy)

    Map.merge(config, %{inflate: inflate_zlib, deflate: deflate_zlib})
  end
end
