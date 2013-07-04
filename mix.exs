defmodule Vaquero.Mixfile do
  use Mix.Project

  def project do
    [ app: :vaquero,
      version: "0.0.1",
      deps: deps,
      dialyzer: [plt_apps: [:erts,:kernel, :stdlib,
                            :crypto, :cowboy],
                 plt_add_deps: true,
                 plt_file: "./.deps.plt"]]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:cowboy]]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [{:cowboy, "0.8.6", [github: "extend/cowboy"]},
     {:jiffy,"0.8.4-3-gd16a4fd", [github: "davisp/jiffy"]},
     {:hackney, "0.4.2", [github: "benoitc/hackney"]},
     {:dialyxir,"0.2.1",[github: "jeremyjh/dialyxir"]}]
  end
end
