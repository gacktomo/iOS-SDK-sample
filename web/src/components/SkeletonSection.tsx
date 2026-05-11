type Props = { title: string; rows?: number }

export function SkeletonSection({ title, rows = 2 }: Props) {
  return (
    <section className="skeleton">
      <h2>{title}</h2>
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="skeleton-row">
          <div className="thumb" />
          <div className="lines">
            <div className="line" />
            <div className="line short" />
          </div>
        </div>
      ))}
    </section>
  )
}
