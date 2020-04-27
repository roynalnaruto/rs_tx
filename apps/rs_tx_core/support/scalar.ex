defmodule RsTxCore.Scalar do
  @moduledoc false

  alias BitHelper
  alias Decimal, as: D
  alias Ecto.UUID
  alias Faker
  alias Mogrify
  alias Timex

  alias RsTxCore.Accounts, as: AccountContext

  def project_dir() do
    case System.fetch_env("PROJECT_DIR") do
      {:ok, root} ->
        Path.expand(root)

      :error ->
        :code.priv_dir(:rs_tx_core)
        |> Path.join("../../../../../")
        |> Path.expand()
    end
  end

  def integer(min \\ 0, max \\ 1_000),
    do: Faker.Random.Elixir.random_between(min, max)

  def url(),
    do: Faker.Internet.url()

  def description(),
    do: Faker.Food.En.description()

  def overview(),
    do: Faker.Food.En.dish()

  def decimal() do
    Faker.Random.Elixir.random_uniform()
    |> D.from_float()
    |> D.round(3)
  end

  def uuid(),
    do: UUID.generate()

  def code(),
    do: Faker.Code.isbn()

  def boolean(),
    do: Faker.Util.pick([false, true])

  def email(),
    do: Faker.Internet.email()

  def birthdate(),
    do: Faker.Date.date_of_birth(18..99)

  def password(),
    do:
      (Faker.String.base64(Enum.random(10..20)) <> "Aa1+")
      |> String.to_charlist()
      |> Enum.shuffle()
      |> to_string()

  def past_date(),
    do: Faker.Date.backward(5 + 365 * Enum.random(1..5))

  def future_date(),
    do: Faker.Date.forward(5 + 365 * Enum.random(1..5))

  def future_datetime(),
    do: Timex.shift(Timex.now(), days: Enum.random(1..100))

  def static_image_file_name() do
    file =
      Enum.random([
        "test.png",
        "test.jpg"
      ])

    project_dir()
    |> Path.join("./apps/rs_tx_core")
    |> Path.join("./test/files")
    |> Path.join(file)
    |> Path.expand()
  end

  def static_image_upload() do
    path = static_image_file_name()

    content_type =
      cond do
        String.ends_with?(path, ".jpg") ->
          "image/jpeg"

        String.ends_with?(path, ".png") ->
          "image/png"

        true ->
          raise "Invalid test file"
      end

    %Plug.Upload{
      filename: Path.basename(path),
      content_type: content_type,
      path: path
    }
  end

  def static_image_data_uri() do
    %Plug.Upload{path: path, content_type: content_type} = static_image_upload()

    path
    |> File.read!()
    |> Base.encode64()
    |> (&"data:#{content_type};base64,#{&1}").()
  end

  def image_file_name() do
    size = Enum.random(100..1000)
    center = floor(size / 2)
    outer_radius = Enum.random(1..floor(center / 2))
    inner_radius = Enum.random(1..outer_radius)

    extension = Enum.random(["png", "jpg"])
    {_res, file_path} = Temp.open!(%{prefix: "rs_tx_core-", suffix: ".#{extension}"})

    %Mogrify.Image{path: file_path, ext: extension}
    |> Mogrify.custom("size", "#{size}x#{size}")
    |> Mogrify.canvas(Faker.Color.name())
    |> Mogrify.custom("fill", Faker.Color.name())
    |> Mogrify.Draw.circle(
      center,
      center,
      center + outer_radius,
      center + outer_radius
    )
    |> Mogrify.custom("fill", Faker.Color.name())
    |> Mogrify.Draw.circle(
      center,
      center,
      center + inner_radius,
      center + inner_radius
    )
    |> Mogrify.create(path: file_path)

    file_path
  end

  def image_upload() do
    path = image_file_name()

    content_type =
      cond do
        String.ends_with?(path, ".jpg") ->
          "image/jpeg"

        String.ends_with?(path, ".png") ->
          "image/png"

        true ->
          raise "Invalid test file"
      end

    %Plug.Upload{
      filename: Path.basename(path),
      content_type: content_type,
      path: path
    }
  end

  def image_data_uri() do
    %Plug.Upload{path: path, content_type: content_type} = image_upload()

    data_uri =
      path
      |> File.read!()
      |> Base.encode64()
      |> (&"data:#{content_type};base64,#{&1}").()

    File.rm(path)

    data_uri
  end

  def hex_bytes(n) do
    :crypto.strong_rand_bytes(n)
    |> Base.encode16(case: :lower)
    |> (&Kernel.<>("0x", &1)).()
  end

  def tx_hash(),
    do: hex_bytes(32)

  defp random_enum_value(enum) do
    enum.__enum_map__()
    |> Enum.map(&elem(&1, 0))
    |> Enum.random()
  end
end
