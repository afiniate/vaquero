defmodule Vaquero.HandlerDict do
  @moduledoc %B"""

    Handlers are only unique by the uniqueness of their routes. Route
    collisions are *not* unique instances of a route. So for example,

       get "/foo/bar/baz" do ....

    and

       get "/foo/bar/..." do ...

    actually collide and so can not live in the same
    handler. HandlerDict modules 'dict-like' ebhaviour around this
    concept, ensuring that the 'route keys' remain unique.

  """
  defrecordp :t, Vaquero.HandlerDict, body: [], size: 0

  def new() do
    t()
  end

  def map(t(body: body), fun) do
    Enum.map(body, fun)
  end

  def put(t(body: body, size: size), route, value) do
    matchable_patterns = make_matchable_pattern(route)
    put(body, size, matchable_patterns, value, [])
  end

  def put_new(t(body: body, size: size), route, value) do
    matchable_patterns = make_matchable_pattern(route)
    put_new(body, size, matchable_patterns, value, [])
  end

  def delete(t(body: body, size: size), route) do
    matchable_patterns = make_matchable_pattern(route)
    delete(body, size, matchable_patterns, [])
  end

  def empty(t) do
    case t do
      t(body: []) ->
        true
      _ ->
        false
    end
  end
  def get(t(body: body), route) do
    matchable_patterns = make_matchable_pattern(route)
    geti(body, matchable_patterns)
  end
  def get(t, route, value) do
    case get(t, route) do
      nil ->
        value
      elt ->
        elt
    end
  end
  def keys(t(body: body)) do
    Enum.map(body, fn({routes, _}) ->
                       routes
                   end)
  end

  def values(t(body: body)) do
    Enum.map(body, fn({_, value}) ->
                       value
                   end)
  end

  defp geti([], _) do
    nil
  end
  defp geti([{key_routes, v} | rest], routes) do
    if patterns_match?(key_routes, routes) do
      v
    else
      geti(rest, routes)
    end
  end


  defp put_new([], size, routes, value, acc) do
    t(body: [{routes, value} | acc], size: size + 1)
  end
  defp put_new([body = {key_routes, _} | rest], size, routes, value, acc) do
    if patterns_match?(key_routes, routes) do
      t(body: acc ++ [body | rest], size: size)
    else
      put_new(rest, size, routes, value, [body | acc])
    end
  end

  defp put([], size, routes, value, acc) do
    t(body: [{routes, value} | acc], size: size + 1)
  end
  defp put([body = {key_routes, _} | rest], size, routes, value, acc) do
    if patterns_match?(key_routes, routes) do
      t(body: acc ++ [{routes, value} | rest], size: size)
    else
      put(rest, size, routes, value, [body | acc])
    end
  end

  defp delete([], size, _routes, acc) do
    t(body: acc, size: size)
  end
  defp delete([pair = {key_routes, _} | rest], size, routes, acc) do
    if patterns_match?(key_routes, routes) do
      delete(rest, size - 1, routes, acc)
    else
      delete(rest, size, routes, [pair | acc])
    end
  end

  defp detail_match([_el | _], [:"..."]) do
    true
  end
  defp detail_match([:"..." ], [_ | _]) do
    true
  end
  defp detail_match([], []) do
    true
  end
  defp detail_match([:var | rest_a], [_el2 | rest_b]) do
    detail_match(rest_a, rest_b)
  end
  defp detail_match([_el1 | rest_a], [:var | rest_b]) do
    detail_match(rest_a, rest_b)
  end
  defp detail_match([el | rest_b], [el | rest_a]) do
    detail_match(rest_a, rest_b)
  end
  defp detail_match(_, _) do
    false
  end

  defp pattern_matches?(pattern_a, pattern_b) do
    if pattern_a == pattern_b do
      true
    else
      detail_match(pattern_a, pattern_b)
    end
  end

  defp patterns_match?(patterns_a, patterns_b) do
    Enum.any?(patterns_a, fn(pattern_a) ->
                              Enum.any?(patterns_b, fn(pattern_b) ->
                                                        pattern_matches?(pattern_a, pattern_b)
                                                  end)
                         end)
  end

  defp make_matchable_pattern(pattern) do
    {patterns, _bindings} = Vaquero.Router.parse_route(pattern)
    Enum.map(patterns, fn(:"...") ->
                          :"..."
                        (el)
                        when Kernel.is_atom(el) ->
                          :var
                        (el) ->
                          el
                      end)
  end


end