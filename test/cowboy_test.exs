Code.require_file "test_helper.exs", __DIR__

defmodule CowboyTest do
  use ExUnit.Case

  defmodule Handler1 do
    use Vaquero

    delete "/path/to/:resource/:bar", hide: [resource] do
      if bar do
        {[ok: {:got_bar, bar}]}
      else
        {[other: {:no_bar, bar}]}
      end
    end

    delete "/path/to/:resource", hide: [resource] do
      {[ok: :ok]}
    end

    post "/path/to/:resource" do
      {[ok: resource]}
    end

    get "/path/to/:resource" do
      {[get: resource]}
    end

    put "/path/to/:resource" do
      {[put: resource]}
    end

    head "/path/to/:resource" do
      {[head: resource]}
    end

  end

  defmodule HandlerSupervisor do
    use Supervisor.Behaviour

    # A convenience to start the supervisor
    def start_link() do
      :supervisor.start_link(__MODULE__, [])
    end

    # The callback invoked when the supervisor starts
    def init([]) do
      children = [CowboyTest.Handler1.get_child_spec(8484)]
      supervise children, strategy: :one_for_one
    end
  end

  setup_all do
    :application.start(:ranch)
    :application.start(:cowboy)
    :application.start(:crypto)
    :application.start(:public_key)
    :application.start(:ssl)
    pid = CowboyTest.HandlerSupervisor.start_link()
    {:ok, [pid: pid]}
  end

  teardown_all meta do
    {:ok, pid} = meta[:pid]
    :erlang.exit(pid, :normal)
    :ok
  end

  test "get" do
    {:ok, status, _headers, client} = :hackney.request(:get, "http://localhost:8484/path/to/my_super_resource", [], "", [])
    {:ok, body, _client} = :hackney.body(client)
    assert 200 == status
    assert {[{"get", "my_super_resource"}]} == :jiffy.decode(body)
  end

  test "put" do
    req_headers = [{<<"Content-Type">>, <<"application/json">>}]
    {:ok, status, _headers, client} = :hackney.request(:put, "http://localhost:8484/path/to/my_super_resource", req_headers, "", [])
    {:ok, body, _client} = :hackney.body(client)
    assert 200 == status
    assert {[{"put", "my_super_resource"}]} == :jiffy.decode(body)
  end

end
