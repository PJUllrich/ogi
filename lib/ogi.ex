defmodule Ogi do
  @moduledoc """
  Renders OpenGraph Images (or really any image you'd like) to PNG using Typst.

  Optionally caches the rendered images based on their filename and assigns in a temporary folder.
  """

  alias Ogi.Cache

  require Logger

  @doc """
  Renders a Typst markup with given assigns and filename to a PNG binary.

  Optionally retrieves a cached version of the image and writes the image to a cache directory if the cache is enabled.
  """
  def render_to_png(filename, typst_markup, assigns \\ [], opts \\ []) do
    with {:error, :not_found} <- Cache.maybe_get_cached_image(filename, assigns),
         {:ok, png} <- do_render_to_png(typst_markup, assigns, opts),
         :ok <- Cache.maybe_put_image(filename, assigns, png) do
      {:ok, png}
    end
  end

  defp do_render_to_png(typst_markup, assigns, opts) do
    case Typst.render_to_png(typst_markup, assigns, opts) do
      {:ok, [png | _rest]} ->
        {:ok, png}

      {:error, error} ->
        Logger.error("Failed to render Typst markup: #{inspect(error)}")

        if path = fallback_image_path() do
          return_fallback_image(path)
        else
          {:error, error}
        end
    end
  end

  defp return_fallback_image(path) do
    case File.read(path) do
      {:ok, image} ->
        {:ok, image}

      {:error, error} ->
        Logger.error("Failed to read fallback image at #{path}: #{inspect(error)}")
        {:error, error}
    end
  end

  defp fallback_image_path, do: Application.get_env(:ogi, :fallback_image_path)

  @doc """
  Renders an OpenGraph Image and sends it as response for a `Plug.Conn`.
  """
  def render_image(%Plug.Conn{} = conn, filename, typst_markup, assigns \\ [], opts \\ []) do
    case render_to_png(filename, typst_markup, assigns, opts) do
      {:ok, png} ->
        conn
        |> Plug.Conn.put_resp_content_type("image/png", nil)
        |> Plug.Conn.put_resp_header(
          "cache-control",
          "public, immutable, no-transform, s-maxage=31536000, max-age=31536000"
        )
        |> Plug.Conn.send_resp(200, png)

      error ->
        Logger.error("Ogi couldn't render the OpenGraph Image for #{filename}: #{inspect(error)}")
        Plug.Conn.send_resp(conn, 404, "Not found")
    end
  end
end
