defmodule Ogi do
  @moduledoc """
  Renders OpenGraph Images (or really any image you'd like) to PNG using Typst.

  Optionally caches the rendered images based on their filename and assigns in a temporary folder.
  """

  alias Ogi.Cache
  alias Ogi.Config

  require Logger

  @doc """
  Renders a Typst markup with given assigns and filename to a PNG binary.

  ## Options

  * `typst_opts` - options that get passed directly to `Typst.render_to_png/3`
  * `cache_enabled` - enable/disable the cache
  * `fallback_image_path` - the filepath to a fallback image if the render fails

  """
  def render_to_png(filename, typst_markup, assigns \\ [], opts \\ []) do
    allowed_opts = [:typst_opts, :cache_enabled, :fallback_image_path]

    default_opts = [
      typst_opts: [],
      cache_enabled: Config.cache_enabled?(),
      fallback_image_path: Config.fallback_image_path()
    ]

    with {:ok, opts} <- Config.validate_opts(opts, allowed_opts, default_opts),
         {:error, :not_found} <-
           Cache.maybe_get_cached_image(filename, assigns, opts[:cache_enabled]),
         {:ok, png} <- do_render_to_png(typst_markup, assigns, opts),
         :ok <- Cache.maybe_put_image(filename, assigns, png, opts[:cache_enabled]) do
      {:ok, png}
    end
  end

  defp do_render_to_png(typst_markup, assigns, opts) do
    case Typst.render_to_png(typst_markup, assigns, opts[:typst_opts]) do
      {:ok, [png | _rest]} ->
        {:ok, png}

      {:error, error} ->
        Logger.error("Failed to render Typst markup: #{inspect(error)}")

        if path = opts[:fallback_image_path] do
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
