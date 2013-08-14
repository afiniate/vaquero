defmodule Vaquero.Router do
  @moduledoc %B"""

   The router system provides a set of macros and functions whose job
   is to produce a very fast router for http methods based on the
   Erlang VM's pattern matching capabilities. This module should
   produce a router thats about as fast as can be produced in Elixir.

  """
  alias Vaquero.HandlerDict, as: VDict

  def parse_route(base_route) do
    [{_, _, routes}] = :cowboy_router.compile([{:_, [{base_route, :_, []}]}])
    {pats, bindings} =
      Enum.map_reduce(routes, :sets.new(),
                    fn ({route, _, _, _}, acc) ->
                         acc = Enum.reduce(route, acc,
                                           fn(:"...", b) ->
                                               b
                                             (element, b)
                                             when Kernel.is_atom(element) ->
                                               :sets.add_element(element, b)
                                             (element, b)
                                             when Kernel.is_binary(element) ->
                                               b
                                           end)
                         {route, acc}
                    end)
    {pats, :sets.to_list(bindings)}
  end

  defp create_arg_list([:"..."], {args, bindings}) do
    {Enum.reverse(args), Enum.reverse(bindings)}
  end
  defp create_arg_list([], {args, bindings}) do
    {Enum.reverse(args), Enum.reverse(bindings)}
  end
  defp create_arg_list([el | rest], {args, bindings})
  when Kernel.is_atom(el) do
    create_arg_list(rest, {[(quote do: var!(unquote(el))) | args], [el | bindings]})
  end
  defp create_arg_list([el | rest], {args, bindings}) do
    create_arg_list(rest, {[(quote do: unquote(el)) | args], bindings})
  end

 defp create_arg_list(pattern) do
   create_arg_list(pattern, {[], []})
  end

  defp make_bindings(bindings) do
    Enum.map(bindings, fn(binding) ->
                           quote do
                             {unquote(binding),
                              var!(unquote(binding))}
                           end
                       end)
   end

  defp create_dispatch_clause(name, pattern) do
    {arg_list, bindings} = create_arg_list(pattern)
    var_bindings = make_bindings(bindings)
    if not Enum.member?(pattern, :"...") do
      quote do
        defp dispatch([unquote_splicing(arg_list)], req) do
          bindings = [unquote_splicing(var_bindings)]
          req = :cowboy_req.set_bindings([], [], bindings, req)
          {:ok, {unquote(name), req}}
        end
      end
    else
      quote do
        defp dispatch([unquote_splicing(arg_list) | acceptor], req) do
          bindings = [unquote_splicing(var_bindings)]
          req = :cowboy_req.set_bindings([], acceptor, bindings, req)
          {:ok, {unquote(name), req}}
        end
      end
    end
  end

  defp create_dispatch_clauses(Vaquero.Handler.Handler[name: name, patterns: patterns]) do
    Enum.map(patterns, create_dispatch_clause(name, &1))
  end

  defp gather_dispatch_clauses(handlers) do
    :lists.flatten(VDict.map(handlers, fn({_, handler}) ->
                                           create_dispatch_clauses(handler)
                                       end))
  end

  def get_router_name(module_name) do
    Kernel.binary_to_atom("#{module_name}.Router")
  end

  def build(name, handlers) do
    dispatch_clauses = gather_dispatch_clauses(handlers)
    router_name = get_router_name(name)
    moduledoc = "Provides routing infrastructure for the rest service defined in #{name} "

     quote do
       defmodule unquote(router_name) do
         @moduledoc unquote(moduledoc)
         @behaviour :cowboy_middleware

         unquote(dispatch_clauses)
         defp dispatch(p, req) do
           {:error, 404, req}
         end

         def execute(req, env) do
           {path, req} = :cowboy_req.path(req)
           result = dispatch(Vaquero.Runtime.split_path(path), req)
           case result do
             {:ok, {name, req}} ->
               new_env = [{:handler, name},
                          {:handler_opts, []} | env]
               {:ok, req, new_env}
             err = {:error, _, _} ->
               err
           end
         end
       end
     end
  end
end
