# OGI (Oh Gee)

Generates and serves OpenGraph Images using Typst.

Inspired by [OG-Image](https://github.com/svycal/og-image/tree/main) but uses Typst instead of Chrome+Puppeteer, so you can add it directly to your Phoenix app.

Generates (beautiful?) share images like this one for my blog [peterullrich.com](https://peterullrich.com)

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

LLMs are pretty good at generating those and you can test them quickly on [typst.app/play](https://typst.app/play/)

Make sure that your markup follows the best-practices of OpenGraph Images which are:

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
    Ogi.render_image(conn, "#{blog_id}.png", typst_markup(), assigns)
  end

  defp typst_markup do
    # Your generated Typst markup goes here.
    #
    # You can dynamically inline variables with:
    # Blog Title: <%= title %>
    #
    # Note: There is *no* @ before the variable other than in HEEx templates!
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

For adding dynamic Metatags, I recommend the [Metatags](https://github.com/johantell/metatags) library:

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

And that's it! You can test this by navigating to the route manually or by using a browser extension that previews OpenGraph information for a website.

## Configuration

Currently, OGI only supports the following configuration:

```elixir
# Whether to cache rendered images or not (default: true)
config :ogi, cache: true|false
```

## Caveats

### Missing fonts

You need to use a font that is available on your system, otherwise Typst will fall back to a `serif` font, unless you set `fallback: false` on a `#text` which means Tyst will simply not render the text at all.

For local development, you can run `typst fonts` to list all available fonts.

For remote deployment, I recommend researching which fonts are installed by default on your runner OS, for example on [Debian](https://wiki.debian.org/Fonts). You can always install the font you like with the package manager and it will become automatically available to Typst.

## ToDo's

- [ ] Emoji Support
- [ ] Clean up Cache when a certain size is reached
- [ ] Add fallback OG Image option if render fails
- [ ] Support for templates
- [ ] Make cache dir path configurable.
- [ ] Allow per-request disabling of fetch/put/both cache operations
- [ ] Allow async rendering. Useful for cache warmup.
- [ ] Unit tests 😬