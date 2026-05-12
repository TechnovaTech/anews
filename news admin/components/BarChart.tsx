interface BarChartProps {
  newsData: number[];
  reelsData: number[];
}

export default function BarChart({ newsData, reelsData }: BarChartProps) {
  const bars = [
    { red: 70, gray: 50 },
    { red: 90, gray: 60 },
    { red: 75, gray: 55 },
    { red: 85, gray: 50 },
    { red: 80, gray: 55 },
    { red: 95, gray: 45 },
    { red: 65, gray: 60 },
    { red: 55, gray: 65 },
    { red: 45, gray: 50 },
    { red: 70, gray: 55 },
    { red: 80, gray: 50 },
    { red: 65, gray: 60 },
    { red: 85, gray: 55 },
  ]

  return (
    <svg width="100%" height="220" viewBox="0 0 400 220" style={{ display: 'block' }}>
      <line x1="30" y1="180" x2="380" y2="180" stroke="#333" strokeWidth="2" />
      {bars.map((bar, i) => {
        const x = 40 + i * 26
        const grayHeight = bar.gray
        const redHeight = bar.red
        return (
          <g key={i}>
            <rect x={x} y={180 - grayHeight} width="20" height={grayHeight} fill="#a0a0a0" />
            <rect x={x} y={180 - grayHeight - redHeight} width="20" height={redHeight} fill="#e31e3a" />
          </g>
        )
      })}
    </svg>
  )
}
