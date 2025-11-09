defmodule Ogi.Config do
  @moduledoc """
  Keeps the configuration options for the OGI package.
  """

  @doc """
  Validates the options against a list of allowed options
  """
  def validate_opts(opts, allowed_opts, default_opts) do
    case Keyword.keys(opts) -- allowed_opts do
      [] -> {:ok, Keyword.merge(default_opts, opts)}
      extra_opts -> {:error, :invalid_opts, extra_opts}
    end
  end

  def cache_dir do
    cache_dir_config() || Path.join(System.tmp_dir!(), "ogi_cache")
  end

  def cache_enabled?, do: Application.get_env(:ogi, :cache, true)
  def cache_dir_config, do: Application.get_env(:ogi, :cache_dir)
  def fallback_image_path, do: Application.get_env(:ogi, :fallback_image_path)
end
