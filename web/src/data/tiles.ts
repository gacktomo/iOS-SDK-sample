import type { IconName } from '../icons'
import type { BridgeAction } from '../bridge'

export type Tile = {
  id: string
  label: string
  icon: IconName
  action?: BridgeAction
}

export const TILES: Tile[] = [
  { id: 'qrLogin', label: 'QRログイン', icon: 'qr', action: { action: 'launchCamera' } },
  { id: 'f2', label: 'Feature 2', icon: 'grid' },
  { id: 'f3', label: 'Feature 3', icon: 'bolt' },
  { id: 'f4', label: 'Feature 4', icon: 'bell' },
  { id: 'f5', label: 'Feature 5', icon: 'gear' },
  { id: 'f6', label: 'Feature 6', icon: 'star' },
  { id: 'f7', label: 'Feature 7', icon: 'heart' },
  { id: 'f8', label: 'Feature 8', icon: 'bookmark' },
  { id: 'f9', label: 'Feature 9', icon: 'tray' },
]
