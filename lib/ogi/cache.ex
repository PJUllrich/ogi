defmodule Ogi.Cache do
  @moduledoc """
  Caches the rendered images based on their filename and assigns in a temporary folder.
  """

  alias Ogi.Config

  @doc """
  Maybe returns `{:ok, cached_image}`, but only if the Cache is enabled
  and the cached image could be found in the cache dir. Otherwise,
  returns `{:error, :not_found}`.
  """
  def maybe_get_cached_image(_filename, _assigns, false = _cache_enabled) do
    {:error, :not_found}
  end

  def maybe_get_cached_image(filename, assigns, _cache_enabled) do
    get(filename, assigns)
  end

  @doc """
  Maybe puts an image into the cached directory, but only if the Cache is enabled.

  Returns `:ok` if the cache is disabled or if the image was written to cache.
  Returns `{:error, io_error}` if writing the image failed.
  """
  def maybe_put_image(_filename, _assigns, _content, false = _cache_enabled) do
    :ok
  end

  def maybe_put_image(filename, assigns, content, _cache_enabled) do
    put(filename, assigns, content)
  end

  @doc """
  Returns the key of a filename in the Cache.

  To prevent key collision, we hash the filename and the assigns
  so that if either changes, we consider the file not cached.
  """
  def get_cache_key(filename, assigns) do
    name_hash = filename |> Path.rootname() |> do_hash()
    assigns_hash = hash_assigns(assigns)

    extension =
      case Path.extname(filename) do
        "" -> ".png"
        extension -> extension
      end

    "#{name_hash}-#{assigns_hash}#{extension}"
  end

  @doc """
  Returns a cached image from the cache dir as `{:ok, binary}`.

  If no cached image can be found, returns `{:error, :not_found}`.
  If another IO error occurs, returns `{:error, error}`.
  """
  def get(filename, assigns) do
    cache_key = get_cache_key(filename, assigns)

    Config.cache_dir()
    |> Path.join(cache_key)
    |> File.read()
    |> case do
      {:ok, binary} -> {:ok, binary}
      {:error, :enoent} -> {:error, :not_found}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Writes an image to the cache folder.

  Returns `:ok` or `{:error, io_error}`.
  """
  def put(filename, assigns, content) do
    File.mkdir_p!(Config.cache_dir())

    cache_key = get_cache_key(filename, assigns)

    Config.cache_dir()
    |> Path.join(cache_key)
    |> File.write(content)
  end

  @doc """
  Cleans out the cache by deleting all stored files.
  """
  def clean! do
    Config.cache_dir()
    |> File.ls()
    |> case do
      {:ok, files} ->
        Enum.each(files, fn file ->
          Config.cache_dir()
          |> Path.join(file)
          |> File.rm()
        end)

      _error ->
        :ok
    end

    :ok
  end

  defp hash_assigns(assigns) do
    assigns
    |> :erlang.term_to_binary()
    |> do_hash()
  end

  defp do_hash(term) when is_binary(term) do
    :sha256
    |> :crypto.hash(term)
    |> Base.url_encode64(padding: false)
  end
end
