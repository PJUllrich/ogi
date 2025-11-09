# OGI (Oh Gee)

Generates and serves OpenGraph Images using Typst.

Inspired by [OG-Image](https://github.com/svycal/og-image/tree/main) but uses
Typst instead of Chrome+Puppeteer, so you can add it directly to your Phoenix
app.

Generates (beautiful?) share images like this one for my blog
[peterullrich.com](https://peterullrich.com)

![](example.png)

## Installation

```elixir
def deps do
  [
    {:ogi, "~> 0.1.0"}
  ]
end
```

## Setup

You need these three things:

1. A Typst template.
2. A Phoenix Controller and Route.
3. An `og:image` metatag in your `<head>` tag.

### 1. The Typst Template

LLMs are pretty good at generating those and you can test them quickly on
[typst.app/play](https://typst.app/play/)

Make sure that your markup follows the best-practices of OpenGraph Images which
are:

- Dimensions of ideally `1200x630`
- No more than `5MB`
- A bit of filled margin at the edges to prevent cropping of text

### 2. The Phoenix Controller and Route

Below is an example controller for serving OG Images for a blog post.

```elixir
defmodule BlogWeb.ImageController do
  use BlogWeb, :controller

  alias Blog.Posts

  def show(conn, %{"id" => blog_id}) do
    post = Posts.get_post_by_id!(blog_id)
    assigns = [title: post.title]
    opts = [root_dir: typst_root(), extra_fonts: [fonts_dir()]]
    Ogi.render_image(conn, "#{blog_id}.png", typst_markup(), assigns, opts)
  end

  # these paths need to be called at runtime for releases
  defp typst_root, do: Application.app_dir(:blog, "priv/typst")
  defp fonts_dir, do: Path.join(typst_root(), "fonts")

  defp typst_markup do
    # Your Typst markup goes here.
    #
    # You can dynamically inline variables with:
    # Blog Title: <%= title %>
    #
    # Note: There is *no* @ before the variable other than in HEEx templates!

    # Example template:
    """
    #set page(width: 1200pt, height: 630pt, margin: 64pt)
    #set text(size: 64pt)

    #place(center + horizon)[
      = Hello World!

      <%= title %>
    ]
    """
  end
end
```

Then add this route to your router:

```elixir
scope "/", BlogWeb do
  get "/og-image/:id", ImageController, :show
end
```

### 3. The Metatag

For adding dynamic Metatags, I recommend the
[Metatags](https://github.com/johantell/metatags) library:

```elixir
# In your Controller or LiveView serving the blog post, add this:
def handle_params(%{"id" => post_id}, _url, socket) do
  post = Posts.get_post_by_id!(post_id)

  socket =
    socket
    |> Metatags.put("og:title", post.title)
    |> Metatags.put("og:description", post.description)
    |> Metatags.put("og:image", url(~p"/og-image/#{post_id}"))

  {:ok, socket}
end
```

And that's it! You can test this by navigating to the route manually or by using
a browser extension that previews OpenGraph information for a website.

## Configuration

Currently, OGI supports the following configurations:

```elixir
config :ogi,
  # Whether to cache rendered images or not (default: true)
  cache: true,
  # Where to store the cache. Defaults to a temporary folder.
  cache_dir: "./some/custom/dir",
  # An optional fallback image which is returned if the rendering
  # of the OG Image using Typst fails.
  fallback_image_path: "./priv/static/some-image.png"
```

## Caveats

### Adding Fonts and Images

Typst has access to system fonts, as well as fonts in directories specified by
the `extra_fonts` option. If a font is unavailable, Typst will fallback to a
`serif` font, unless you set `fallback: false` on a `#text`. In this case Typst
will simply not render the text at all.

If you have the `typst-cli` installed on your system, you can run `typst fonts`
to list all available fonts.

For remote deployment, it is recommended to bundle fonts with your application.
The example above places fonts in the `priv/typst/fonts` directory, and images
and other file resources in `priv/typst`.

## ToDo's

- [ ] Emoji Support
- [ ] Support for templates
- [ ] Clean up Cache when a certain size is reached
- [ ] Allow per-request disabling of fetch/put/both cache operations
- [ ] Allow async rendering. Useful for cache warmup.
- [x] Add fallback OG Image option if render fails
- [x] Make cache dir path configurable.
- [x] Unit tests 😬
