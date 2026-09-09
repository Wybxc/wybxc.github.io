#let _content_state = sys.inputs.at("_aster", default: none)
#let _collections = if _content_state == none {
  // The LSP evaluates files without Aster's injected runtime protocol.
  (:)
} else {
  assert(
    _content_state.protocol == 9,
    message: "incompatible runtime protocol with the Aster binary",
  )
  _content_state.collections
}

#let aster-version = if _content_state == none { none } else { _content_state.version }
#let aster-dev = if _content_state == none { none } else { _content_state.dev }

#let route-param(name, default: none) = if _content_state == none {
  default
} else {
  _content_state.route.param(name, default: default)
}
#let route-pages() = if _content_state == none { () } else { _content_state.routes.pages() }

#let get-collection-ids(name) = {
  _collections.at(name, default: (:)).keys().sorted()
}

#let get-collection(name) = {
  _collections.at(name, default: (:)).values().sorted(key: entry => entry.id)
}

#let get-entry(collection, id) = {
  _collections.at(collection, default: (:)).at(id, default: none)
}

#let settings = toml("/aster.toml")
#let target = dictionary(std).at("target", default: () => "paged")
