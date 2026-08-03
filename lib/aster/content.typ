// Aster Content Collections — public interface
//
// Place this file in your project at lib/aster/content.typ and import:
//   #import "/lib/aster/content.typ": get-collection, get-collection-ids,
//     get-entry

#let _state = sys.inputs.at("_aster", default: none)
#assert(
  _state != none,
  message: "Aster content collections are not available; " +
    "maybe not running in an Aster project context?"
)
#assert(
  _state.protocol == 4,
  message: "unsupported Aster content protocol; this version of " +
    "content.typ is incompatible with the Aster binary",
)

#let _collections = _state.collections

// Return the sorted ids in a collection without loading any entry bodies.
#let get-collection-ids(name) = {
  _collections.at(name, default: (:)).keys().sorted()
}

// Return all entry modules in a collection as an array, sorted by id.
#let get-collection(name) = {
  _collections
    .at(name, default: (:))
    .values()
    .sorted(key: entry => entry.id)
}

// Return a single entry module by collection name and id.
// Returns `none` when not found.
#let get-entry(collection, id) = {
  _collections
    .at(collection, default: (:))
    .at(id, default: none)
}
