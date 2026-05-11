export type BridgeAction =
  | { action: 'launchCamera' }
  | { action: 'close' }

type WebKitWindow = Window & {
  webkit?: {
    messageHandlers?: {
      uiBridge?: { postMessage: (payload: unknown) => void }
    }
  }
  AndroidBridge?: { postMessage: (payload: string) => void }
}

export function postToNative(payload: BridgeAction): void {
  const w = window as WebKitWindow
  try {
    if (w.webkit?.messageHandlers?.uiBridge) {
      w.webkit.messageHandlers.uiBridge.postMessage(payload)
      return
    }
    if (w.AndroidBridge) {
      w.AndroidBridge.postMessage(JSON.stringify(payload))
      return
    }
    console.warn('native bridge unavailable', payload)
  } catch (e) {
    console.error('native bridge failed', e)
  }
}
