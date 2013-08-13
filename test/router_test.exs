Code.require_file "test_helper.exs", __DIR__

defmodule RouterTest do
  use ExUnit.Case

  test "bindings test" do
    {pat, bindings} = Vaquero.Router.parse_route("/path/to/resource")
    assert bindings == []
    assert pat == [["path", "to", "resource"]]

    {pat, bindings} = Vaquero.Router.parse_route("/hats/:name/prices")
    assert bindings == [:name]
    assert pat == [["hats", :name, "prices"]]

    {pat, bindings} = Vaquero.Router.parse_route("/hats/[page/:number]")
    assert bindings == [:number]
    assert pat == [["hats"],
                   ["hats", "page", :number]]

    {pat, bindings} = Vaquero.Router.parse_route("/hats/[page/[:number]]")
    assert bindings == [:number]
    assert pat == [["hats"],
                   ["hats", "page"],
                   ["hats", "page", :number]]

    {pat, bindings} = Vaquero.Router.parse_route("/hats/[...]")
    assert bindings == []
    assert pat == [["hats", :"..."]]

    {pat, bindings} = Vaquero.Router.parse_route("/hats/:name/:name")
    assert bindings == [:name]
    assert pat == [["hats", :name, :name]]

    {pat, bindings} = Vaquero.Router.parse_route("/hats/:name/[:name]")
    assert bindings == [:name]
    assert pat == [["hats", :name],
                   ["hats", :name, :name]]

    {pat, bindings} = Vaquero.Router.parse_route("/:user/[...]")
    assert bindings == [:user]
    assert pat == [[:user, :"..."]]
  end
end
