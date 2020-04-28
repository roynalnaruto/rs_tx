defmodule RsTxCore.Factories.ProjectsFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias RsTxCore.Scalar

      alias RsTxCore.Projects, as: ProjectContext
      alias ProjectContext.{
        Project,
        ProjectMetadata
      }

      def create_project_factory do
        %{
          public_key: Scalar.hex_bytes(33),
          metadata: %{
            url: Scalar.url(),
            overview: Scalar.overview(),
            description: Scalar.description(),
            icon: Scalar.static_image_upload()
          }
        }
      end
    end
  end
end
