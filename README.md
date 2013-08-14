Vaquero
=======

Vaquero is a system designed to make it trivially easy to add a REST
interface to an existing Erlang OTP system. With that in mind it
provides the ability to trivially design REST routes and call into
your system to produce values. It also has the ability to handle
default encoding and decoding of json values and efficient route
dispatching.

Vaquero is designed to be a very thin layer on top of cowboy. The
request object you get is a simple cowboy request object and can be
interacted with via the normal cowboy api.

Your route should return one of the following values.

* A cowboy request object already setup with correct return values
* An output object, either as a binary, iolist, or `jiffy` json object
* A tuple of `output` and `status` where output is as above and status
  is the HTTP status code to return.
* A tuple of output (as described above), standard cowboy headers and
  status (as described above)

Vaquero supports the following HTTP methods

* GET
* HEAD
* PUT
* PATCH
* POST
* DELETE
* OPTIONS

Vaquero's Routes are the same as Cowboy's routes and are documented
[here](https://github.com/extend/cowboy/blob/master/guide/routing.md). Vaquero
does not yet support host routes, only path routes.

When you specify a variable in a route that *becomes* a variable in
the body of your handler. If you are not going to use that variable
for some reason you need to hide it as below.

    get "/one/two/:three", hide: [three], req: req do
      {[{:unsupported, "three is not used anywhere"}]}
    end

Vaquero supports direct access to the req parameter of the cowboy
request, but you need to supply a name for it if you want to use
it. Otherwise it will be hidden from you.

### Example

    defmodule RestRouter do
        use Vaquero

        get "/", content_type: :json do
         {[{:woot, ["I", "am", "a", "valid", "json", "value"]}]}
        end

        get "/", content_type: :html, req: req do
          "HTMLs should return a binary or io list"
        end
     end

Data Format
-----------

    Elixir                        JSON            Elixir
    ==========================================================================

    :null                      -> null           -> :null
    :nil                       -> "nil"          -> :nil
    true                       -> true           -> true
    false                      -> false          -> false
    'hi'                       -> [104, 105]     -> 'hi'
    "hi"                       -> "hi"           -> "hi"
    :hi                        -> "hi"           -> "hi"
    1                          -> 1              -> 1
    1.25                       -> 1.25           -> 1.25
    []                         -> []             -> []
    [true, 1.0]                -> [true, 1.0]    -> [true, 1.0]
    {[]}                       -> {}             -> {[]}
    {[{:foo, :bar}]}           -> {"foo": "bar"} -> {[{"foo", "bar"}]}
    {[{"foo", "bar"}]}         -> {"foo": "bar"} -> {[{"foo", "bar"}]}
