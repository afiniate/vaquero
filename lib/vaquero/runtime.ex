defmodule Vaquero.Runtime do
  @moduledoc %B"""

    Provides several functions that a Vaquero service uses during
    runtime. Everything else in Vaquero is a compile time entity.

   """
  def handle_output(req, state, _content_type, _binary_content_type, raw_output)
  when Kernel.is_tuple(raw_output) and :erlang.element(1, raw_output) == :http_req do
    {:ok, req, state}
  end
  def handle_output(req, state, content_type, binary_content_type, raw_output) do
    status = output_to_status(raw_output)
    headers = output_to_headers(binary_content_type, raw_output)
    output = convert_output(content_type, raw_output)
    {:ok, req} = :cowboy_req.reply(status, headers, output, req)
    {:ok, req, state}
  end

  defp output_to_status({status, _output}) do
    status
  end
  defp output_to_status({status, _headers, _output}) do
    status
  end
  defp output_to_status(false) do
    500
  end
  defp output_to_status(_) do
    200
  end

  defp convert_output(content_type, {_status, output}) do
    convert_output(content_type, output)
  end
  defp convert_output(content_type, {_status, _headers, output}) do
    convert_output(content_type, output)
  end
  defp convert_output(_content_type, output)
  when Kernel.is_binary(output) do
    output
  end
  defp convert_output(_content_type, output)
  when Kernel.is_list(output) do
    output
  end
  defp convert_output(_content_type, atom)
  when Kernel.is_atom(atom) do
    ""
  end
  defp convert_output(:json, {output}) do
    :jiffy.encode({output})
  end
  defp convert_output("application/json", {output}) do
    :jiffy.encode({output})
  end
  defp convert_output(content_type, _) do
    raise Vaquero.InvalidOutput, content_type: Vaquero.Handler.content_type_to_binary(content_type)
  end

  defp output_to_headers(content_type, {_status, headers, _output}) do
    if not :proplists.is_defined("Content-Type") do
      [{"Content-Type", content_type} | headers]
    else
      headers
    end
  end
  defp output_to_headers(content_type, _) do
    [{"Content-Type", content_type}]
  end

  @doc """
     Split a path into a list of path segments.

     Following RFC2396, this function may return path segments containing any
     character, including <em>/</em> if, and only if, a <em>/</em> was escaped
     and part of a path segment.
   """
  @spec split_path(binary) :: [binary]
  def split_path(<< ?/, path :: bits >>) do
    split_path(path, [])
  end
  def split_path(path) do
    raise Vaquero.BadPath, path: path
  end

  def split_path(path, acc) do
    case :binary.match(path, "/") do
      :nomatch when path == <<>> ->
        :lists.reverse(lc s inlist acc, do: :cowboy_http.urldecode(s))
      :nomatch ->
        :lists.reverse(lc s inlist [path | acc], do: :cowboy_http.urldecode(s))
      {pos, _} ->
        << segment :: [size(pos),binary], _ :: size(8), rest :: bits >> = path
        split_path(rest, [segment | acc])
    end
  end

end
