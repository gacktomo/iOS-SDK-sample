import { TileGrid } from './components/TileGrid'
import { SkeletonSection } from './components/SkeletonSection'
import { TILES } from './data/tiles'
import { postToNative } from './bridge'

export default function App() {
  return (
    <>
      <header>
        <h1>UISDK</h1>
        <button
          type="button"
          className="close"
          aria-label="閉じる"
          onClick={() => postToNative({ action: 'close' })}
        >
          ×
        </button>
      </header>

      <TileGrid tiles={TILES} />

      <SkeletonSection title="Recommended" />
      <SkeletonSection title="Recent Activity" />
    </>
  )
}
