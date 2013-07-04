Code.require_file "test_helper.exs", __DIR__

defmodule HandlerTest do
  use ExUnit.Case
  alias HandlerTest.Handler1.REST1, as: REST1
  alias HandlerTest.Handler1.REST2, as: REST2
  alias HandlerTest.Handler2.REST1, as: H2REST1
  alias HandlerTest.Handler1.Router, as: Router
  defmodule Handler1 do
    use Vaquero

    delete "/path/to/:resource/:bar", hide: [resource] do
      if bar do
        {[ok: {[got_bar: bar]}]}
      else
        {[other: {[no_bar: bar]}]}
      end
    end

    delete "/path/to/:resource", hide: [resource] do
      {[ok: :ok]}
    end

    post "/path/to/:resource" do
      {[ok: resource]}
    end

    get "/path/to/:resource" do
      {[json_get: resource]}
    end

    head "/path/to/:resource" do
      {[head: resource]}
    end

    get "/path/to/:resource", content_type: :html do
      "html_get: #{resource}"
    end

    get "/path/to/:resource", content_type: {"application", "vaquero"} do
      "vaquero_get: #{resource}"
    end

    head "/path/to/:resource", content_type: :html do
      "{[head: #{resource}]}"
    end

    put "/path/to/:resource" do
      {[put: resource]}
    end

    patch "/path/to/:resource" do
      {[patch: resource]}
    end

    options "/path/to/:resource" do
      {[option_ok: resource]}
    end

    patch "/path/to/other/thing/[...]" do
      {[ok: "this is a test"]}
    end

  end

  defmodule Handler2 do
    use Vaquero, authorize: check_authorization

    def check_authorization(_req, _state) do
      false
    end

    get "/test/foo" do
      :ok
    end
  end

  test "assert delete with options and vars" do

    req0 = :cowboy_req.new(:socket, HandlerTest, :peer, "DELETE", "/path/to/resource/bar",
                           "",:"HTTP/1.1", [], "test.com", 8080, "", false,
                           false, :undefined)


    req1 = :cowboy_req.set_bindings([], ["path", "to", "resource", "bar"],
                                    [{:bar, "bar"}], req0)
    req2 = :cowboy_req.set_bindings([], ["path", "to", "resource", "bar"],
                                    [], req0)

    {:ok, _, :state} = REST1.handle("DELETE", req1, :state, "application/json")
    assert "{\"ok\":{\"got_bar\":\"bar\"}}" == :erlang.get(:body)

    {:ok, _, :state} = REST1.handle("DELETE", req2, :state, "application/json")
    assert "{\"other\":{\"no_bar\":\"nil\"}}" == :erlang.get(:body)
  end

  test "complete handler" do
    req0 = :cowboy_req.new(:socket, HandlerTest, :peer, "DELETE", "/path/to/resource/bar",
                           "",:"HTTP/1.1", [], "test.com", 8080, "", false,
                           false, :undefined)


    {:ok, _, :state} = REST2.handle("DELETE", req0, :state, "application/json")
    assert "{\"ok\":\"ok\"}" == :erlang.get(:body)

    req1 = :cowboy_req.set_bindings([], ["path", "to", "resource", "bar"],
                                    [{:resource, "resource"}], req0)
    {:ok, _, :state} = REST2.handle("POST", req1, :state, "application/json")

    req0 = :cowboy_req.new(:socket, HandlerTest, :peer, "GET", "/path/to/bar",
                           "", :"HTTP/1.1", [], "test.com", 8080, "", false,
                           false, :undefined)
    req1 = :cowboy_req.set_bindings([], ["path", "to", "bar"],
                                    [{:resource, "bar"}], req0)
    {:ok, _, _} = REST2.handle("GET", req1, :state, "application/json")
    assert "{\"json_get\":\"bar\"}" == :erlang.get(:body)
    {:ok, _, _} = REST2.handle("GET", req1, :state, "text/html")
    assert "html_get: bar" == :erlang.get(:body)
    {:ok, _, _} = REST2.handle("GET", req1, :state, "application/vaquero")
    assert "vaquero_get: bar" == :erlang.get(:body)

    req0 = :cowboy_req.new(:socket, HandlerTest, :peer, "HEAD", "/path/to/bar",
                           "",:"HTTP/1.1", [], "test.com", 8080, "", false,
                           false, :undefined)
    req1 = :cowboy_req.set_bindings([], ["path", "to", "bar"],
                                    [{:resource, "baz"}], req0)

    {:ok, _, :state} = REST2.handle("HEAD", req1, :state, "application/json")
    assert "" == :erlang.get(:body)
    {:ok, _, :state} = REST2.handle("HEAD", req1, :state, "text/html")
    assert "" == :erlang.get(:body)

    req0 = :cowboy_req.new(:socket, HandlerTest, :peer, "PUT", "/path/to/bar",
                           "",:"HTTP/1.1", [], "test.com", 8080, "", false,
                           false, :undefined)
    req1 = :cowboy_req.set_bindings([], ["path", "to", "bar"],
                                    [{:resource, "bar"}], req0)

    {:ok, _, :state} = REST2.handle("PUT", req1, :state, "application/json")
    assert "{\"put\":\"bar\"}" == :erlang.get(:body)

    req0 = :cowboy_req.new(:socket, HandlerTest, :peer, "PATCH", "/path/to/bar",
                           "",:"HTTP/1.1", [], "test.com", 8080, "", false,
                           false, :undefined)
    req1 = :cowboy_req.set_bindings([], ["path", "to", "bar"],
                                    [{:resource, "baz"}], req0)
    {:ok, _, :state} = REST2.handle("PATCH", req1, :state, "application/json")
    assert "{\"patch\":\"baz\"}" == :erlang.get(:body)

    req0 = :cowboy_req.new(:socket, HandlerTest, :peer, "OPTIONS", "/path/to/resource/bar",
                           "",:"HTTP/1.1", [], "test.com", 8080, "", false,
                           false, :undefined)
    req1 = :cowboy_req.set_bindings([], ["path", "to", "resource", "bar"],
                                    [{:resource, "resource"}], req0)

    {:ok, _, :state} = REST2.handle("OPTIONS", req1, :state, "application/json")
    assert "{\"option_ok\":\"resource\"}" == :erlang.get(:body)

  end


  test "test generated router" do
    assert ([__info__: 1, execute: 2, module_info: 0, module_info: 1]
            == Enum.sort(HandlerTest.Handler1.Router.module_info(:exports)))
    req0 = :cowboy_req.new(:socket, HandlerTest, :peer, "DELETE", "/path/to/resource/bar",
                           "",:"HTTP/1.1", [], "test.com", 8080, "", false,
                           false, :undefined)
    {:ok, req0, env} = Router.execute(req0, [])
    assert [handler: HandlerTest.Handler1.REST1, handler_opts: []] == env
    {bindings, _} = :cowboy_req.bindings(req0)
    assert [resource: "resource", bar: "bar"] == bindings

    req0 = :cowboy_req.new(:socket, HandlerTest, :peer, "DELETE", "/path/to/resource",
                           "",:"HTTP/1.1", [], "test.com", 8080, "", false,
                           false, :undefined)

    {:ok, req0, env} = Router.execute(req0, [])
    assert [handler: HandlerTest.Handler1.REST2, handler_opts: []] == env
    assert {[resource: "resource"], _} = :cowboy_req.bindings(req0)

    req0 = :cowboy_req.new(:socket, HandlerTest, :peer, "PATCH", "/path/to/other/thing/like/this",
                           "",:"HTTP/1.1", [], "test.com", 8080, "", false,
                           false, :undefined)

    {:ok, req0, env} = Router.execute(req0, [])
    assert [handler: HandlerTest.Handler1.REST3, handler_opts: []] == env
    {bindings, _}  = :cowboy_req.bindings(req0)
    assert [] == bindings
    {path_info, _}  = :cowboy_req.path_info(req0)
    assert ["like", "this"] == path_info
  end

  test "good handler" do
    assert [__info__: 1,
            get_child_spec: 1,
            get_child_spec: 2,
            module_info: 0,
            module_info: 1] == Enum.sort(HandlerTest.Handler1.module_info(:exports))
  end

  def send(_, [_, _, _, body]) do
    :erlang.put(:body, body)
    :ok
  end
end
