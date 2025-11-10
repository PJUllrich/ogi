# v0.2.2

- Fixed `Ogi.Cache.clean!()` exception if cache folder doesn't exist.

# v0.2.1

- Added documentation and tests

# v0.2.0

## Breaking changes

- Typst options passed to `Ogi.render_to_png/4` must be nested under `typst_opts` now:

```elixir
# Before
opts = [root_dir: "priv/typst"]
Ogi.render_to_png(filename, markup, assigns, opts)

# After
opts = [typst_opts: [root_dir: "priv/typst"]]
Ogi.render_to_png(filename, markup, assigns, opts)
```

## Additions

- Add `fallback_image_path` and `cache_dir` config options.
- Validate options received in `Ogi.render_to_png/4`
- Add Quokka for consistent formatting (👀👀👀 Mr. G.W.)

# v0.1.0

- Added `render_to_png/4` and `render_image/5` for rendering images using Typst from your controller
- Added basic caching without clean-up