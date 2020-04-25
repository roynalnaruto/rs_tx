defmodule RsTxApiWeb.Schema.CustomScalarTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  alias MIME
  alias Timex
  alias URI
  alias URL

  defp parse_uri(uri) do
    URL.Data.parse(uri)
  rescue
    _ -> :error
  end

  scalar :data_url do
    description(
      "A base64-encoded data URL (`data:image/png;base64;...`) represented as a object with data and file type but no filename"
    )

    serialize(fn value ->
      if is_binary(value) do
        Base.encode64(value)
      else
        to_string(value)
      end
    end)

    parse(fn value ->
      case value do
        %Absinthe.Blueprint.Input.String{value: text} ->
          with %{scheme: "data"} = uri <- URI.parse(text),
               %URL.Data{data: data, mediatype: content_type} <- parse_uri(uri) do
            with [extension | _] <- MIME.extensions(content_type),
                 {:ok, path} <- Plug.Upload.random_file("upload"),
                 {:ok, file} <- File.open(path, [:write, :binary]),
                 :ok <- IO.binwrite(file, data),
                 :ok <- File.close(file) do
              {:ok,
               %Plug.Upload{
                 filename: "#{Path.basename(path)}.#{extension}",
                 content_type: content_type,
                 path: path
               }}
            else
              _ -> :error
            end
          else
            _ -> :error
          end

        %Absinthe.Blueprint.Input.Null{} ->
          {:ok, nil}

        _ ->
          :error
      end
    end)
  end

  scalar :timestamp do
    description("A unix timestamp represented by an integer")

    serialize(&Timex.to_unix/1)

    parse(fn value ->
      case value do
        %Absinthe.Blueprint.Input.Integer{value: text} ->
          {:ok, Timex.from_unix(text)}

        %Absinthe.Blueprint.Input.Null{} ->
          {:ok, nil}

        _ ->
          :error
      end
    end)
  end
end
