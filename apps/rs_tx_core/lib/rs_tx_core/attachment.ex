defmodule RsTxCore.Attachment do
  @moduledoc false

  use RsTxCore.Schema

  alias Ecto.Changeset
  alias ExImageInfo
  alias Mogrify
  alias Plug
  alias URI
  alias URL

  alias __MODULE__, as: Entity

  @type t :: __MODULE__

  schema "attachments" do
    field(:original, :string)
    field(:thumbnail, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(t, Plug.Upload.t()) :: Changeset.t()
  def changeset(%Entity{} = entity, %Plug.Upload{path: path}) do
    max_size = max_file_size()

    entity
    |> Changeset.cast(%{}, [])
    |> case do
      %Changeset{valid?: true} = changeset ->
        case File.stat(path) do
          {:ok, %{size: size}} when size > max_size ->
            Changeset.add_error(changeset, :file_size, "is too large")

          {:ok, _} ->
            changeset

          {:errror, _} ->
            Changeset.add_error(changeset, :file, "does not exist")
        end

      changeset ->
        changeset
    end
    |> case do
      %Changeset{valid?: true} = changeset ->
        data = File.read!(path)

        case ExImageInfo.info(data) do
          {type, width, height, _variant} ->
            cond do
              type not in valid_mime_types() ->
                Changeset.add_error(changeset, :file_type, "is invalid")

              width > max_width() ->
                Changeset.add_error(changeset, :image_width, "is too large")

              height > max_height() ->
                Changeset.add_error(changeset, :image_height, "is too large")

              true ->
                original =
                  data
                  |> Base.encode64()
                  |> (&"data:#{type};base64,#{&1}").()

                %Mogrify.Image{path: thumbnail_path} =
                  path
                  |> Mogrify.open()
                  |> Mogrify.resize("100x100")
                  |> Mogrify.gravity("center")
                  |> Mogrify.extent("100x100")
                  |> Mogrify.format("png")
                  |> Mogrify.save()

                thumbnail =
                  thumbnail_path
                  |> File.read!()
                  |> Base.encode64()
                  |> (&"data:image/png;base64,#{&1}").()

                File.rm(thumbnail_path)

                Changeset.change(changeset, %{
                  original: original,
                  thumbnail: thumbnail
                })
            end

          nil ->
            Changeset.add_error(changeset, :file_type, "is invalid")
        end

      changeset ->
        changeset
    end
  end

  defp valid_mime_types() do
    config()[:mime_types] || ["image/jpeg", "image/png"]
  end

  defp max_width() do
    config()[:max_width] || 2048
  end

  defp max_height() do
    config()[:max_height] || 2048
  end

  defp max_file_size() do
    config()[:max_file_size] || 10 * 1024 * 1024
  end

  defp config() do
    Application.get_env(:rs_tx_core, __MODULE__)
  end
end
