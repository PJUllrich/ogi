defmodule OgiTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  @simple_markup """
  #set page(width: 1200pt, height: 630pt, margin: 64pt)
  #set text(size: 64pt)

  #place(center + horizon)[
    = Hello World!

    <%= title %>
  ]
  """

  describe "render_to_png/4" do
    test "renders a simple markup" do
      filename = "test-1.png"
      assigns = [title: "Welcome!"]

      assert {:ok, <<137, 80, 78, 71, 13, 10, 26, _rest::binary>>} =
               Ogi.render_to_png(filename, @simple_markup, assigns)
    end

    test "caches a rendered image" do
      filename = "test-2.png"
      assigns = [title: "Welcome!"]

      {:ok, image} =
        Ogi.render_to_png(filename, @simple_markup, assigns)

      assert Ogi.Cache.get(filename, assigns) == {:ok, image}
    end

    test "returns a cached image" do
      filename = "test-3.png"
      assigns = [title: "Welcome!"]
      :ok = Ogi.Cache.put(filename, assigns, <<123, 123, 123>>)

      assert {:ok, <<123, 123, 123>>} =
               Ogi.render_to_png(filename, @simple_markup, assigns)
    end

    test "returns an error if a markup fails to render" do
      filename = "test-4.png"

      invalid_markup = """
      #set page(width: 1200pt, height: 630pt, margin: 64pt)
      #set text(size: 64pt)

      #place(
        center + horizon,
        // Leading is an unknown option for 'place'
        leading: 1.5rem
        [Hello World!]
      )
      """

      assert capture_log(fn ->
               assert {:error, error} =
                        Ogi.render_to_png(filename, invalid_markup)

               assert error =~ "expected expression\n  Source: leading: 1.5rem"
             end) =~ "Failed to render Typst markup"
    end
  end
end
