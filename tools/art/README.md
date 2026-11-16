# tools/art

Scripts and manifests that produced the village's art and its first layouts.

## Still useful

- `build_variants.lua`, `build_details.lua` — rebuild the building variant sheets and rooftop
  details from their `.aseprite` sources in Aseprite (story 009).
- `villagers.lua` — rebuild the villager look and role sheets (story 010).
- `building_variants.json`, `villager_looks.json`, `landmarks_a.json`, `landmarks_b.json` —
  the artists' manifests: sheet sizes, anchors, detail and seat points.

## Obsolete: do not re-run to change the map

The village is now placed in the editor. The ground is a TileMapLayer and every building, tree,
wall, lantern and prop is a node saved in `src/village/village_scene.tscn`. Each building carries
its own door. Edit the map there.

- `gen_village.py` (story 008), `variety.py` (story 009), `edge14.py` (story 014) wrote `map`,
  `placements` and `doors` into `assets/data/village_layout.json`. Nothing reads those keys any
  more, so running them changes nothing in the game. They are kept as a record of how the layout
  was made.
- `tools/scene/bake_ground.gd` and `tools/scene/bake_objects.gd` did the one-time move into the
  scene and refuse to run again.
