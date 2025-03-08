defmodule Mix.Tasks.Desktop.Installer do
  use Mix.Task
  # import Desktop.Deployment.Tooling
  @moduledoc false

  @shortdoc "Creates a platform specific installer package."
  def run(_args, config \\ Mix.Project.config()) do
    xcode_platform_name = System.get_env("PLATFORM_NAME")

    if xcode_platform_name == "iphonesimulator" or
         xcode_platform_name == "iphoneos" do
      IO.puts("ios build, ignoring #{xcode_platform_name}")
      System.halt(0)
    end

    release =
      Enum.find(config[:releases] || [], fn {_name, rel} ->
        steps = Keyword.get(rel, :steps, [])
        Enum.member?(steps, &Desktop.Deployment.generate_installer/1)
      end)

    if release == nil do
      IO.puts("""
        Desktop.Installer couldn't find a release with steps configured
        to include the Deployment task `&Desktop.Deployment.generate_installer/1`.

        Add the `generate_installer/1` callback at least to one of your
        release configurations in your mix.exs:

        ```
        def project do
          [
            releases: [
              default: [
                steps: [:assemble, &Desktop.Deployment.generate_installer/1]
              ]
            ]
          ]
        end
        ```
      """)

      System.halt(1)
    end

    {name, _} = release

    {_ret, status} =
      System.cmd("mix", ["release", Atom.to_string(name), "--overwrite"],
        env: [{"MIX_ENV", "prod"}],
        into: IO.binstream(:stdio, :line),
        stderr_to_stdout: true
      )

    if status != 0 do
      System.halt(status)
    end
  end
end
