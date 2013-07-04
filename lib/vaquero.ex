### copyright 10io, Inc.
defmodule Vaquero do
  @moduledoc %B"""
   This module provides the macros (and only the macros) that vaquero
   uses to create handlers. It makes use of Vaquero.Support to do the
   actual heavy lifting

  """

  defexception BadPath, path: nil do def message(exception) do
  "Bad path provided: #{exception.path}" end end

  defexception ConflictingRoutes, path_a: nil, path_b: nil do
    def message(exception) do
      "Conflicting routes provided, path: #{exception.path_a} conflicts with path: #{exception.path_b}"
    end
  end

  defexception ExistingHandler, route: nil, type: nil, detail: nil do
    def message(exception) do
      if exception.detail do
        "Handler #{exception.detail}/#{exception.type} for #{exception.route} already exists"
      else
        "Handler #{exception.type} for #{exception.route} already exists"
      end
    end
  end

  defexception InvalidOutput, content_type: nil do
    def message(exception) do
      "Output does not match Content-Type: #{exception.content_type}"
    end
  end

  defmacro __using__(opts) do
    caller = __CALLER__.module
    Module.put_attribute(caller, :vaquero, opts || [])
    Module.put_attribute(caller, :vaquero_handler_count, 1)

    router_name = Vaquero.Router.get_router_name(caller)

    quote do
      import Vaquero.Private
      @before_compile Vaquero

      def get_child_spec(port) do
        get_child_spec(100, port)
      end
      def get_child_spec(pool_size, port) do
        :ranch.child_spec(unquote(caller), pool_size,
                          :ranch_tcp, [{:port, port}],
                          :cowboy_protocol, [{:env, []},
                                             {:middlewares, [unquote(router_name),
                                                             :cowboy_handler]}])
      end
    end
  end

  defmacro __before_compile__(env) do
    Vaquero.Support.build(env)
  end

  defmodule Private do
    alias Vaquero.Support, as: Support

    defmacro get(route, opts) do
      module = __CALLER__.module
      opts = Support.merge_opts(module, opts) |>
                       Keyword.put(:type, :get) |>
                       Support.content_type(:json)
      Support.add_handler(module, route, opts)
    end

    defmacro get(route, opts, body) do
      all = opts ++ body
      quote do
        get(unquote(route), unquote(all))
      end
    end

    defmacro put(route, opts) do
      module = __CALLER__.module
      opts = Support.merge_opts(module, opts) |>
                       Keyword.put(:type, :put) |>
                       Support.content_type(:json)
      Support.add_handler(module, route, opts)
    end

    defmacro put(route, opts, body) do
      all = opts ++ body
      quote do
        put(unquote(route), unquote(all))
      end
    end

    defmacro post(route, opts) do
      module = __CALLER__.module
      opts = Support.merge_opts(module, opts) |>
                       Keyword.put(:type, :post) |>
                       Support.content_type(:json)
      Support.add_handler(module, route, opts)
    end

    defmacro post(route, opts, body) do
      all = opts ++ body
      quote do
        post(unquote(route), unquote(all))
      end
    end

    defmacro patch(route, opts) do
      module = __CALLER__.module
      opts = Support.merge_opts(module, opts) |>
                       Keyword.put(:type, :patch) |>
                       Support.content_type(:json)
      Support.add_handler(module, route, opts)
    end

    defmacro patch(route, opts, body) do
      all = opts ++ body
      quote do
        patch(unquote(route), unquote(all))
      end
    end

    defmacro options(route, opts) do
      module = __CALLER__.module
      opts = Support.merge_opts(module, opts) |>
                       Keyword.put(:type, :options) |>
                       Support.content_type(:json)
      Support.add_handler(module, route, opts)
    end

    defmacro options(route, opts, body) do
      all = opts ++ body
      quote do
         options(unquote(route), unquote(all))
      end
    end

    defmacro delete(route, opts) do
      module = __CALLER__.module
      opts = Support.merge_opts(module, opts) |>
                       Keyword.put(:type, :delete) |>
                       Support.content_type(:json)
      Support.add_handler(module, route, opts)
      nil
    end

    defmacro delete(route, opts, body) do
      all = opts ++ body
      quote do
        delete(unquote(route), unquote(all))
      end
    end

    defmacro head(route, opts) do
      module = __CALLER__.module
      opts = Support.merge_opts(module, opts) |>
                       Keyword.put(:type, :head) |>
                       Support.content_type(:json)
      Support.add_handler(module, route, opts)
    end

    defmacro head(route, opts, body) do
      all = opts ++ body
      quote do
        head(unquote(route), unquote(all))
      end
    end
  end
end
