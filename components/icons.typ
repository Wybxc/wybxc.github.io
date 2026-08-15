#import "@preview/iconify:0.5.3": icon-svg, provide-icons

// Load the icon collections used by this site. Must be placed in the
// document flow before any icon is rendered.
#let provide-site-icons() = provide-icons(
  json("/assets/icons/lucide.json"),
  json("/assets/icons/simple-icons.json"),
)

// Rebuild a parsed SVG node as an inline HTML element.
#let _html-node(node) = {
  if type(node) == dictionary and node.at("tag", default: none) != none {
    html.elem(
      node.tag,
      attrs: node.attrs,
      node.children.map(_html-node).join(),
    )
  }
}

// An inline icon in HTML output.
//
// Unlike iconify's own `icon`, the SVG is emitted as a real inline `<svg>`
// element that keeps `currentColor`, so CSS `color` still styles the icon
// (needed for dark-mode theming).
//
// - name (str): icon name in `collection:name` form, e.g. `"lucide:rss"`.
// - size (str): HTML size for the `width`/`height` attributes, e.g. `"1em"`.
// - class (str): value for the `class` attribute.
#let icon(name, size: "1em", class: none) = context {
  let svg = icon-svg(name).replace(text.fill.to-hex(), "currentColor")
  let root = xml(bytes(svg)).first()
  // Normalize the camel-cased attribute names dropped by the XML parser.
  let attrs = root.attrs + (width: size, height: size)
  let attrs = if "viewbox" in attrs {
    let viewbox = attrs.remove("viewbox")
    attrs + (viewBox: viewbox)
  } else {
    attrs
  }
  let attrs = if class != none {
    attrs + (class: class)
  } else {
    attrs
  }
  html.elem("svg", attrs: attrs, root.children.map(_html-node).join())
}
