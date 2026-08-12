#let _content_state = sys.inputs.at("_aster", default: none)
#let _collections = if _content_state == none {
  // The LSP evaluates files without Aster's injected runtime protocol.
  (:)
} else {
  assert(
    _content_state.protocol == 7,
    message: "incompatible runtime protocol with the Aster binary",
  )
  _content_state.collections
}
#let _route = if _content_state == none {
  none
} else {
  _content_state.at("route", default: none)
}

#let aster-version = if _content_state == none { none } else { _content_state.version }
#let route-params = if _route == none { (:) } else { _route.params }

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
