Code.require_file "test_helper.exs", __DIR__

defmodule DictTest do
  use ExUnit.Case
  alias Vaquero.HandlerDict, as: VDict

  test "test add/get/delete" do
    route = "/foo/boo/baz"
    conflicting_route = "/foo/boo/:..."

    d = VDict.new()
    d = VDict.put(d, route, 3)
    assert 3 == VDict.get(d, route)
    assert 3 == VDict.get(d, conflicting_route)

    d = VDict.put(d, conflicting_route, 4)
    assert 4 == VDict.get(d, route)
    assert 4 == VDict.get(d, conflicting_route)

    d = VDict.delete(d, conflicting_route)
    assert nil = VDict.get(d, conflicting_route)
    assert nil = VDict.get(d, route)
  end


end
