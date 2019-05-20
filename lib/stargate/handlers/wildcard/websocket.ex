defmodule Stargate.Handler.Wildcard.Websocket do
  @moduledoc false

  alias Stargate.Vessel.Websocket.Frame

  def connect(_conn, config) do
    IO.puts("connect")
    {:ok, config}
  end

  def handle_text_frame(_text, config) do
    response = Frame.format_server_frame("Hi there", :text)
    config.transport.send(config.socket, response)
    config
  end
end
