### copyright 10io, Inc.
defmodule Vaquero.Handler do
  @moduledoc %B"""

  The handler takes care of building an individual implementation of a
  cowboy http handler. A single Vaquero Service may produce a number of
  handlers depending on the routes provided.

  """

  defrecord Handler, [name: nil,
                      parent: nil,
                      patterns: nil,
                      bindings: nil,
                      opts: nil,
                      route: nil,
                      handlers: ListDict.new]



  def new(module_name, route, opts) do
    count = get_count(module_name)
    {patterns, bindings} = Vaquero.Router.parse_route(route)
    name = create_name(module_name, count)
    Handler[name: name,
            parent: module_name,
            route: route,
            patterns: patterns,
            bindings: bindings,
            opts: opts]
  end

  @doc """
    Adds a handler for a specific http method to the handler
  """
  def add_handler(t = Handler[handlers: handlers, route: route], opts) do
    method = opts[:type]
    method_handler = Dict.get(handlers, method) || ListDict.new
    content_type = opts[:content_type]
    if Dict.has_key?(method_handler, content_type) do
      raise ExistingHandler, route: route, type: :delete, detail: content_type
    else
      handlers = Dict.put(handlers, method,
                          Dict.put(method_handler, content_type, opts))
      t.handlers(handlers)
    end
  end

  defp create_name(module_name, count) do
    :erlang.list_to_atom('#{module_name}.REST#{count}')
  end

  defp get_count(module) do
    count = Module.get_attribute(module, :vaquero_handler_count)
    Module.put_attribute(module, :vaquero_handler_count, count + 1)
    count
  end

  def content_type_to_binary(:json) do
    "application/json"
  end
  def content_type_to_binary(:html) do
    "text/html"
  end
  def content_type_to_binary({t1, t2}) do
    "#{t1}/#{t2}"
  end

  defp gen_bindings(Handler[bindings: bindings], options) do
    Enum.filter_map(bindings,
                    is_not_hidden?(&1, options),
                    fn(binding) ->
                        quote do
                          {var!(unquote(binding)), req} =
                            :cowboy_req.binding(unquote(binding),
                                                req,
                                                nil)
                        end
                    end)
  end

  defp is_not_hidden?(value, opts) do
    hidden = opts[:hide] || []
    Enum.all?(hidden,
              fn({pos, _, _}) ->
                  value != pos
              end)
  end

  def gen_content_type_case(t, method, {_, options}) do
    content_type = options[:content_type]
    binary_content_type = content_type_to_binary(content_type)
    bindings = gen_bindings(t, options)
    body = options[:do]
    req = options[:req] || (quote do: req)
    quote do
      def handle(unquote(method), unquote(req), state, unquote(binary_content_type)) do
        unquote(bindings)
        result = unquote(body)

        Vaquero.Runtime.handle_output(unquote(req),
                                      state,
                                      unquote(content_type),
                                      unquote(binary_content_type),
                                      result)

      end
    end
  end

  defp default_reply() do
    quote do
      def handle(_, req, state, _) do
        {:ok, :cowboy_req.reply(405, [], <<>>, req), state}
      end
    end
  end

  defp gen_handler_clause(nil, _t, _method) do
    nil
  end
  defp gen_handler_clause(handlers, t, method) do
    Enum.map(handlers, gen_content_type_case(t, method, &1))
  end


  def build(t = Handler[name: name, handlers: all_handlers], _env) do
    get = all_handlers[:get] |> gen_handler_clause(t, "GET")
    put = all_handlers[:put] |> gen_handler_clause(t, "PUT")
    head = all_handlers[:head] |> gen_handler_clause(t, "HEAD")
    patch = all_handlers[:patch] |> gen_handler_clause(t, "PATCH")
    post = all_handlers[:post] |> gen_handler_clause(t, "POST")
    delete = all_handlers[:delete] |> gen_handler_clause(t, "DELETE")
    options = all_handlers[:options] |> gen_handler_clause(t, "OPTIONS")
    default = default_reply()

    quote do
      defmodule unquote(name) do

        def init(_transport, req, []) do
          {:ok, req, nil}
        end

        unquote(get)
        unquote(put)
        unquote(head)
        unquote(patch)
        unquote(post)
        unquote(delete)
        unquote(options)
        unquote(default)

        def handle(req, state) do
          {headers, req} = :cowboy_req.headers(req)
          content_type = Dict.get(headers, "content_type") || <<"application/json">>
          {method, req} = :cowboy_req.method(req)
          handle(method, req, state, content_type)
        end

        def terminate(_reason, _req, _state) do
          :ok
        end
      end
    end
  end
end
