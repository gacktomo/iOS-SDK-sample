export type BridgeAction =
  | { action: 'launchCamera' }
  | { action: 'close' }

type BridgeWindow = Window & {
  webkit?: {
    messageHandlers?: {
      uiBridge?: { postMessage: (payload: unknown) => void }
    }
  }
  uiBridge?: { postMessage: (payload: string) => void }
}

export function postToNative(payload: BridgeAction): void {
  const w = window as BridgeWindow
  try {
    if (w.webkit?.messageHandlers?.uiBridge) {
      w.webkit.messageHandlers.uiBridge.postMessage(payload)
      return
    }
    if (w.uiBridge) {
      w.uiBridge.postMessage(JSON.stringify(payload))
      return
    }
    console.warn('native bridge unavailable', payload)
  } catch (e) {
    console.error('native bridge failed', e)
  }
}
