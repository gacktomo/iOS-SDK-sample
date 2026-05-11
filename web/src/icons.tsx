import type { SVGProps } from 'react'

type IconProps = SVGProps<SVGSVGElement>

const base: IconProps = {
  viewBox: '0 0 24 24',
  'aria-hidden': true,
}

export const QrIcon = (p: IconProps) => (
  <svg {...base} {...p}>
    <path d="M3 3h8v8H3V3zm2 2v4h4V5H5zm8-2h8v8h-8V3zm2 2v4h4V5h-4zM3 13h8v8H3v-8zm2 2v4h4v-4H5zm8 0h2v2h-2v-2zm4 0h2v2h-2v-2zm-4 4h2v2h-2v-2zm2-2h2v2h-2v-2zm2 2h2v2h-2v-2zm0-4h2v2h-2v-2z" />
  </svg>
)
export const GridIcon = (p: IconProps) => (
  <svg {...base} {...p}>
    <path d="M3 3h8v8H3V3zm10 0h8v8h-8V3zM3 13h8v8H3v-8zm10 0h8v8h-8v-8z" />
  </svg>
)
export const BoltIcon = (p: IconProps) => (
  <svg {...base} {...p}>
    <path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z" />
  </svg>
)
export const BellIcon = (p: IconProps) => (
  <svg {...base} {...p}>
    <path d="M12 22a2 2 0 0 0 2-2h-4a2 2 0 0 0 2 2zm6-6V11a6 6 0 1 0-12 0v5l-2 2v1h16v-1l-2-2z" />
  </svg>
)
export const GearIcon = (p: IconProps) => (
  <svg {...base} {...p}>
    <path d="M19.4 13a7.5 7.5 0 0 0 0-2l2-1.6-2-3.4-2.4 1a7 7 0 0 0-1.7-1L15 3H9l-.3 2.9a7 7 0 0 0-1.7 1l-2.4-1-2 3.4L4.6 11a7.5 7.5 0 0 0 0 2L2.6 14.6l2 3.4 2.4-1a7 7 0 0 0 1.7 1L9 21h6l.3-2.9a7 7 0 0 0 1.7-1l2.4 1 2-3.4-2-1.7zM12 15.5a3.5 3.5 0 1 1 0-7 3.5 3.5 0 0 1 0 7z" />
  </svg>
)
export const StarIcon = (p: IconProps) => (
  <svg {...base} {...p}>
    <path d="M12 2l3 7h7l-5.5 4.5L18 21l-6-4-6 4 1.5-7.5L2 9h7z" />
  </svg>
)
export const HeartIcon = (p: IconProps) => (
  <svg {...base} {...p}>
    <path d="M12 21s-7-4.5-9.5-9A5.5 5.5 0 0 1 12 6a5.5 5.5 0 0 1 9.5 6c-2.5 4.5-9.5 9-9.5 9z" />
  </svg>
)
export const BookmarkIcon = (p: IconProps) => (
  <svg {...base} {...p}>
    <path d="M6 2h12v20l-6-4-6 4V2z" />
  </svg>
)
export const TrayIcon = (p: IconProps) => (
  <svg {...base} {...p}>
    <path d="M3 13h4l2 3h6l2-3h4v6H3v-6zm0-8h18v6h-5l-2 3h-4l-2-3H3V5z" />
  </svg>
)

export const ICONS = {
  qr: QrIcon,
  grid: GridIcon,
  bolt: BoltIcon,
  bell: BellIcon,
  gear: GearIcon,
  star: StarIcon,
  heart: HeartIcon,
  bookmark: BookmarkIcon,
  tray: TrayIcon,
} as const

export type IconName = keyof typeof ICONS
