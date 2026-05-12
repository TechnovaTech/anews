export default function LineChart({ data }: { data: number }) {
  const points = Array.from({ length: 12 }, (_, i) => {
    const x = 20 + i * 30
    const y = 180 - (Math.random() * data * 0.5)
    return `${x},${y}`
  }).join(' ')

  return (
    <svg width="100%" height="220" viewBox="0 0 400 220" style={{ display: 'block' }}>
      <polyline
        points={points}
        fill="none"
        stroke="#e31e3a"
        strokeWidth="3"
      />
      <line x1="20" y1="200" x2="20" y2="20" stroke="#333" strokeWidth="2" />
      <line x1="20" y1="200" x2="380" y2="200" stroke="#333" strokeWidth="2" />
    </svg>
  )
}
