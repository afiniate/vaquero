### copyright 10io, Inc.
defmodule Vaquero.Support do
  @moduledoc %B"""

  Support generates the code created from a Vaquero Service. It
  coordinates the Vaquero.Handler and Vaquero.Router macro generation
  facilities to produce a full implementation of a Vaquero Service.

  """

  alias Vaquero.Handler, as: Handler
  alias Vaquero.HandlerDict, as: VDict

  defp get_handler(module, route) do
    handlers = Module.get_attribute(module, :vaquero_handlers) || VDict.new
    {case VDict.get(handlers, route) do
       nil ->
         Vaquero.Handler.new(module, route,
                             parent_opts(module))

      elt ->
         elt
     end, handlers}
  end

  def add_handler(module, route, opts) do
    {handler, handlers} = get_handler(module, route)
    handler = Handler.add_handler(handler, opts)
    Module.put_attribute(module, :vaquero_handlers, VDict.put(handlers, route, handler))
  end

  def parent_opts(module) do
    Module.get_attribute(module, :vaquero) || []
  end

  def merge_opts(module, opts) do
    Keyword.merge(parent_opts(module), opts)
  end

  def build(env) do
    handlers = Module.get_attribute(env.module, :vaquero_handlers)
    handler_mods = VDict.map(handlers, fn({_, handler}) ->
                                           Vaquero.Handler.build(handler, env)
                                       end)
    [Vaquero.Router.build(env.module, handlers) |
     handler_mods]

  end

  def content_type(opts, default_type) do
    content_type = opts[:content_type] ||  default_type
    Keyword.put(opts, :content_type, content_type)
  end

end