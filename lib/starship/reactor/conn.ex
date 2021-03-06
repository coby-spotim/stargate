defmodule Starship.Reactor.Conn do
  @moduledoc """
  The connection struct for the `Starship` Webserver.
  """

  alias Starship.Errors
  alias Starship.Reactor.Conn
  alias Starship.Reactor.Conn.Method

  @typedoc "The body of an HTTP request"
  @type body :: binary
  @typedoc "An HTTP header"
  @type header :: {binary, binary}
  @typedoc "HTTP header list"
  @type headers :: [header]
  @typedoc "The HTTP version of a request"
  @type http_version :: :"HTTP/0.9" | :"HTTP/1.0" | :"HTTP/1.1" | :"HTTP/2.0" | :"HTTP/3.0"
  @typedoc "The parsed query of an HTTP request"
  @type query :: map

  @http_versions %{
    "HTTP/0.9" => :"HTTP/0.9",
    "HTTP/1.0" => :"HTTP/1.0",
    "HTTP/1.1" => :"HTTP/1.1",
    "HTTP/2.0" => :"HTTP/2.0",
    "HTTP/3.0" => :"HTTP/3.0"
  }

  @http_methods %{
    "GET" => Method.get(),
    "HEAD" => Method.head(),
    "POST" => Method.post(),
    "PUT" => Method.put(),
    "DELETE" => Method.delete(),
    "CONNECT" => Method.connect(),
    "OPTIONS" => Method.options(),
    "TRACE" => Method.trace(),
    "PATCH" => Method.patch()
  }

  @typedoc """
  A connection struct for an HTTP request made to the server.

  This defines all parts of the connection made to the server.
  """
  @type t :: %Conn{
          body: body,
          headers: headers,
          http_version: http_version,
          path: binary,
          query: query,
          method: Method.t()
        }

  defstruct body: "",
            headers: [],
            http_version: :"HTTP/1.1",
            path: "/",
            query: %{},
            method: Method.get()

  @spec http_version(binary) :: {:ok, http_version} | {:error, Exception.t()}
  def http_version(version) do
    case Map.fetch(@http_versions, version) do
      :error -> {:error, Errors.HttpVersionNotSupportedError.exception(version)}
      {:ok, v} -> validate_http_version(v)
    end
  end

  @spec validate_http_version(http_version) :: {:ok, http_version} | {:error, Exception.t()}
  defp validate_http_version(version) do
    if valid_http_version?(version) do
      {:ok, version}
    else
      {:error, Errors.HttpVersionNotSupportedError.exception(version)}
    end
  end

  @spec valid_http_version?(http_version) :: boolean
  defp valid_http_version?(:"HTTP/1.1"), do: true
  defp valid_http_version?(:"HTTP/1.0"), do: true
  defp valid_http_version?(:"HTTP/0.9"), do: true
  # defp valid_http_version?(:"HTTP/2.0"), do: true
  # defp valid_http_version?(:"HTTP/3.0"), do: true
  defp valid_http_version?(_), do: false

  @spec http_method(binary) :: {:ok, Method.t()} | {:error, Exception.t()}
  def http_method(method) do
    case Map.fetch(@http_methods, method) do
      :error -> {:error, Errors.MethodNotAllowedError.exception(method)}
      m -> m
    end
  end
end
