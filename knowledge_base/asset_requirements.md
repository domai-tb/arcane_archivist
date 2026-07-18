# Arcane Archivist Asset Requirements

This is the planned asset checklist for the playable `0.1` slice. Placeholder art is acceptable until the corresponding milestone is locked.

## Required for `0.1`

| Asset | Format | Target size | Priority | Notes |
| --- | --- | --- | --- | --- |
| Library room tiles / background | PNG or SVG | 16/32 px tiles, 1280x800 composition | High | Must keep desk, shelf, and dungeon entrance readable. |
| Player character | PNG sprite sheet | 32x32 or 48x48 frames | High | Idle, walk, interact; transparent background. |
| Enemy: Ash Wisp | PNG sprite sheet | 32x32 or 48x48 frames | High | Idle, move, hit, defeat. |
| Enemy: Archive Husk | PNG sprite sheet | 48x48 or 64x64 frames | Medium | Optional second enemy for encounter variety. |
| Tome reward | PNG or SVG | 64x64 icon | High | Must be visually distinct in the reward room and archive. |
| Starter card icons (5) | SVG or PNG | 32x32 and 64x64 | High | Swift Step, Arc Strike, Ward Sign, Arc Bolt, Astral Focus. |
| Card/status symbols | SVG | 24x24 and 48x48 | High | Cost, cooldown, health, shield, insight. |
| Dungeon room props | PNG or SVG | 16/32 px tiles or 64x64 props | Medium | Walls, floor, hazard, chest/cache, exit marker. |
| UI panel/button theme | SVG/PNG plus Godot Theme | 9-slice panels, 32 px base | High | Readable at 1280x800 and scalable for touch. |
| Interaction markers | SVG or PNG | 24x24 and 48x48 | High | Request desk, archive shelf, dungeon entrance, interact prompt. |

## Audio (optional for `0.1`, required before polish)

| Asset | Format | Target | Priority |
| --- | --- | --- | --- |
| Hub ambient loop | OGG | 44.1 kHz stereo, seamless | Medium |
| Dungeon ambient loop | OGG | 44.1 kHz stereo, seamless | Medium |
| Card play / hit / block / pickup sounds | WAV or OGG | Short, normalized effects | Medium |
| Success and failure stingers | WAV or OGG | 2–5 seconds | Medium |

## Production constraints

- Keep source files layered/editable where practical; export runtime textures as PNG or SVG.
- Use transparent backgrounds for characters, enemies, cards, icons, and props.
- Avoid text baked into art so localization and accessibility remain possible.
- Provide nearest-neighbour and filtered import variants only when pixel-art readability requires it.
- Every final asset must have a license/source note before release.

Later milestones will add library-wing art, biome variants, relic/tome catalogue art, narrative portraits, defense-event assets, and platform-specific store media.
