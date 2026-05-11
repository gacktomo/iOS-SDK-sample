import { ICONS } from '../icons'
import { postToNative } from '../bridge'
import type { Tile } from '../data/tiles'

type Props = { tiles: Tile[] }

export function TileGrid({ tiles }: Props) {
  return (
    <div className="grid">
      {tiles.map((t) => {
        const Icon = ICONS[t.icon]
        const enabled = Boolean(t.action)
        return (
          <button
            key={t.id}
            type="button"
            className={'tile' + (enabled ? ' enabled' : '')}
            disabled={!enabled}
            onClick={enabled && t.action ? () => postToNative(t.action!) : undefined}
          >
            <span className="icon">
              <Icon />
            </span>
            <span className="label">{t.label}</span>
          </button>
        )
      })}
    </div>
  )
}
