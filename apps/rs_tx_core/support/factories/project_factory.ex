defmodule RsTxCore.Factories.ProjectFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias RsTxCore.Scalar

      alias RsTxCore.Projects, as: ProjectContext
      alias ProjectContext.{
        Project,
        ProjectMetadata
      }

      def project_factory(attrs) do
        project_fields =
          Project.__struct__()
          |> Map.keys()
          |> List.delete(:__meta__)
          |> List.delete(:__struct__)

        {project_attrs, extra_attrs} = Map.split(attrs, project_fields)

        user = build(:confirmed_user, extra_attrs)

        project_metadata = build(:project_metadata, extra_attrs)

        %Project{
          id: Scalar.uuid(),
          public_key: Scalar.hex_bytes(33),
          user: user,
          metadata: project_metadata
        } |> merge_attributes(project_attrs)
      end

      def project_metadata_factory(attrs) do
        %ProjectMetadata{
          id: Scalar.uuid(),
          url: Scalar.url(),
          overview: Scalar.overview(),
          description: Scalar.description(),
          icon: build(:attachment)
        } |> merge_attributes(attrs)
      end
    end
  end
end
