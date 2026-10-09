export default function Logo({ size = 48 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 120 120" role="img" aria-label="SARI logo">
      <defs>
        <linearGradient id="sari-green" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#1E6E5A" />
          <stop offset="1" stopColor="#144A3D" />
        </linearGradient>
        <linearGradient id="sari-amber" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#FFDF73" />
          <stop offset="1" stopColor="#C8861A" />
        </linearGradient>
      </defs>
      <rect width="120" height="120" rx="30" fill="url(#sari-green)" />
      <rect x="12" y="14" width="96" height="40" rx="10" fill="url(#sari-amber)" />
      <text x="60" y="45" textAnchor="middle" fontFamily="Baloo 2, sans-serif" fontWeight="900" fontSize="32" fill="#144A3D" letterSpacing="1.5">SARI</text>
      {/* Tindahan awning */}
      <path d="M8 66 Q8 58 16 58 H104 Q112 58 112 66 L108 80 Q100 88 90 80 Q80 88 70 80 Q60 88 50 80 Q40 88 30 80 Q20 88 12 80 Z" fill="#ffffff" />
      <path d="M30 80 Q40 88 50 80 M70 80 Q80 88 90 80" stroke="#B8E1D6" strokeWidth="2" fill="none" />
      {/* Tindahan counter & window */}
      <rect x="24" y="90" width="72" height="22" rx="6" fill="#ffffff" opacity=".95" />
      <rect x="50" y="94" width="20" height="18" rx="3" fill="#1E6E5A" />
    </svg>
  )
}
