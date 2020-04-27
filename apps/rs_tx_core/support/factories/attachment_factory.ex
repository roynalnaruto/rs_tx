defmodule RsTxCore.Factories.AttachmentFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias RsTxCore.Scalar

      alias RsTxCore.Attachment

      def attachment_factory() do
        %Attachment{
          original: Scalar.static_image_data_uri(),
          thumbnail: Scalar.image_data_uri()
        }
      end
    end
  end
end
