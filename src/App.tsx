import { useEffect, useRef, useState } from 'react'
import {
  Sparkles, ShoppingCart, BarChart3, User, MessageCircle, Mic, Send, Search, ScanLine, Soup, CupSoda, Cookie,
  Egg, Wheat, SprayCan, Package, Moon, Type, Languages, ShieldCheck, Download, Store, Undo2, Check, Share2, Printer,
  ClipboardList, AlertTriangle, TrendingUp, Wallet, Trophy, Boxes, MapPin, Heart, Home, Bell, ChevronRight, Lock,
  Ban, WifiOff, X, Truck, ListChecks, Repeat, Camera, RefreshCw, Plus, Lightbulb, CalendarDays, Tag, ArrowUp, ArrowDown, FileText, Flame, Percent, Fish, CookingPot, Trash2, Minus, QrCode, BadgeCheck, ArrowLeft, Loader2, type LucideIcon,
} from 'lucide-react'
import { QRCodeSVG } from 'qrcode.react'
import Logo from './Logo'

type Role = 'buyer' | 'seller'
type Tab = 'agent' | 'center' | 'right' | 'settings' | 'inventory'
type BuyerOrder = { id: string; store: string; buyer: string; lines: { id: number; name: string; qty: number; price: number }[]; total: number; status: 'Naipadala' | 'Na-scan' }
type Verify = { status: 'none' | 'pending' | 'ok' | 'fail'; idMasked?: string }
type StoreType = 'Sari-sari' | 'Gulay' | 'Rice' | 'Carenderia'
type Item = { id: number; name: string; price: number; cost: number; cat: string; stock: number; perDay: number; pack: number; unit: string; supplier: string }

const CAT_ICON: Record<string, LucideIcon> = { Noodles: Soup, Drinks: CupSoda, Snacks: Cookie, Fresh: Egg, Rice: Wheat, Home: SprayCan, Canned: Fish, Cooking: CookingPot }
const INITIAL: Item[] = [
  { id: 1, name: 'Lucky Me Pancit Canton', price: 16, cost: 12.5, cat: 'Noodles', stock: 14, perDay: 18, pack: 24, unit: 'box', supplier: 'Metro Supply' },
  { id: 2, name: 'Kopiko 3-in-1', price: 8, cost: 6.2, cat: 'Drinks', stock: 42, perDay: 30, pack: 30, unit: 'pack', supplier: 'Metro Supply' },
  { id: 3, name: 'Coke Sakto', price: 15, cost: 12, cat: 'Drinks', stock: 18, perDay: 10, pack: 24, unit: 'case', supplier: 'Batangas Beverage' },
  { id: 4, name: 'Piattos', price: 20, cost: 16, cat: 'Snacks', stock: 9, perDay: 6, pack: 12, unit: 'box', supplier: 'Metro Supply' },
  { id: 5, name: 'Itlog (1pc)', price: 9, cost: 7.5, cat: 'Fresh', stock: 30, perDay: 20, pack: 30, unit: 'tray', supplier: 'Aling Rosa Farm' },
  { id: 6, name: 'Bigas Sinandomeng (1kg)', price: 58, cost: 52, cat: 'Rice', stock: 3, perDay: 9, pack: 25, unit: 'sako', supplier: 'Lipa Rice Mill' },
  { id: 7, name: 'Safeguard', price: 38, cost: 31, cat: 'Home', stock: 12, perDay: 3, pack: 12, unit: 'box', supplier: 'Metro Supply' },
  { id: 8, name: 'Surf Sachet', price: 7, cost: 5.4, cat: 'Home', stock: 60, perDay: 20, pack: 60, unit: 'bundle', supplier: 'Metro Supply' },
  { id: 9, name: 'Mang Tomas', price: 24, cost: 19, cat: 'Snacks', stock: 11, perDay: 4, pack: 12, unit: 'box', supplier: 'Metro Supply' },
  { id: 10, name: 'Nissin Cup Noodles', price: 28, cost: 23, cat: 'Noodles', stock: 20, perDay: 5, pack: 24, unit: 'box', supplier: 'Metro Supply' },
  { id: 11, name: 'Payless Pancit Canton', price: 14, cost: 11, cat: 'Noodles', stock: 26, perDay: 8, pack: 30, unit: 'box', supplier: 'Metro Supply' },
  { id: 12, name: 'Milo Sachet', price: 9, cost: 7, cat: 'Drinks', stock: 35, perDay: 14, pack: 48, unit: 'pack', supplier: 'Batangas Beverage' },
  { id: 13, name: 'C2 Green Tea 230ml', price: 20, cost: 16, cat: 'Drinks', stock: 24, perDay: 8, pack: 24, unit: 'case', supplier: 'Batangas Beverage' },
  { id: 14, name: 'Chippy BBQ', price: 10, cost: 8, cat: 'Snacks', stock: 40, perDay: 12, pack: 50, unit: 'box', supplier: 'Metro Supply' },
  { id: 15, name: 'Oishi Prawn Crackers', price: 12, cost: 9.5, cat: 'Snacks', stock: 22, perDay: 6, pack: 24, unit: 'box', supplier: 'Metro Supply' },
  { id: 16, name: 'Ligo Sardinas', price: 24, cost: 20, cat: 'Canned', stock: 16, perDay: 5, pack: 24, unit: 'case', supplier: 'Metro Supply' },
  { id: 17, name: 'Century Tuna Flakes', price: 38, cost: 32, cat: 'Canned', stock: 12, perDay: 3, pack: 24, unit: 'case', supplier: 'Metro Supply' },
  { id: 18, name: 'Silver Swan Toyo', price: 18, cost: 14, cat: 'Cooking', stock: 18, perDay: 4, pack: 24, unit: 'case', supplier: 'Metro Supply' },
  { id: 19, name: 'Datu Puti Suka', price: 18, cost: 14, cat: 'Cooking', stock: 15, perDay: 4, pack: 24, unit: 'case', supplier: 'Metro Supply' },
  { id: 20, name: 'Asin (Iodized)', price: 10, cost: 7, cat: 'Cooking', stock: 30, perDay: 5, pack: 40, unit: 'bundle', supplier: 'Metro Supply' },
  { id: 21, name: 'Baguio Oil 1L', price: 95, cost: 84, cat: 'Cooking', stock: 11, perDay: 2, pack: 12, unit: 'case', supplier: 'Metro Supply' },
  { id: 22, name: 'Bigas Dinorado (1kg)', price: 62, cost: 55, cat: 'Rice', stock: 25, perDay: 4, pack: 25, unit: 'sako', supplier: 'Lipa Rice Mill' },
  { id: 23, name: 'Colgate 25g', price: 22, cost: 18, cat: 'Home', stock: 14, perDay: 2, pack: 12, unit: 'box', supplier: 'Metro Supply' },
]
const CATS = ['Lahat', 'Noodles', 'Drinks', 'Snacks', 'Fresh', 'Rice', 'Home', 'Cooking', 'Canned']
const LOW = 10
const peso = (n: number) => '₱' + Math.round(n).toLocaleString('en-PH')

// reorder engine: ordinary code, the agent only triggers it
type Line = { id: number; name: string; qty: number; unit: string; supplier: string; cost: number }
const needed = (i: Item, days: number): Line | null => {
  const packs = Math.ceil((i.perDay * days - i.stock) / i.pack)
  return packs > 0 ? { id: i.id, name: i.name, qty: packs, unit: i.unit, supplier: i.supplier, cost: packs * i.pack * i.cost } : null
}

type Draft = { kind: 'restock' | 'utang' | 'prep'; title: string; lines: Line[]; total: number; note?: string }
type Msg = { from: 'me' | 'sari'; text: string; risk?: 'Read' | 'Draft' | 'Change' | 'Blocked'; draft?: Draft; state?: 'open' | 'second' | 'done' | 'undone' }
type Log = { t: string; tool: string; args: string; by: string }

/* ---------- small UI ---------- */
const Card = ({ children, className = '' }: { children: React.ReactNode; className?: string }) => (
  <div className={`bg-card rounded-3xl p-4 shadow-sm border border-black/5 ${className}`}>{children}</div>
)
const Chip = ({ active, onClick, children }: { active?: boolean; onClick: () => void; children: React.ReactNode }) => (
  <button onClick={onClick} className={`shrink-0 min-h-12 px-4 rounded-full font-bold text-sm border-2 ${active ? 'bg-brand text-white border-brand' : 'bg-card border-brand/25 hover:bg-brand-soft'}`}>{children}</button>
)
const Row = ({ icon: Icon, label, sub, onClick }: { icon: LucideIcon; label: string; sub?: string; onClick?: () => void }) => (
  <button onClick={onClick} className="w-full flex items-center gap-3 text-left min-h-14 px-4 rounded-2xl bg-card border border-black/5 font-bold hover:bg-brand-soft">
    <Icon className="size-6 text-brand shrink-0" /><span className="flex-1">{label}{sub && <span className="block text-xs font-semibold opacity-70">{sub}</span>}</span><ChevronRight className="size-5 opacity-50" />
  </button>
)
const RISK_STYLE = { Read: 'bg-brand-soft text-brand', Draft: 'bg-amber-soft text-amber', Change: 'bg-brand text-white', Blocked: 'bg-ink text-bg' }

/* ---------- AI AGENT ---------- */
function Agent(p: { role: Role; items: Item[]; storeType: StoreType; modelReady: boolean; setModelReady: (v: boolean) => void; limit: number; log: (l: Omit<Log, 't'>) => void; onConfirm: (d: Draft) => void; sentToStore: (n: number) => void }) {
  const { role, items, storeType, modelReady, limit } = p
  const seller = role === 'seller'
  const [msgs, setMsgs] = useState<Msg[]>([{ from: 'sari', text: seller ? 'Kumusta po! Sabihin o i-type ang kailangan ng tindahan. Ako ang maghahanda ng draft, kayo ang magko-confirm.' : 'Hello po! Hanapin natin ang kailangan ninyo sa mga malapit na tindahan. Gagawa ako ng listahan.' }])
  const [text, setText] = useState('')
  const [heard, setHeard] = useState<string | null>(null)
  const [listening, setListening] = useState(false)
  const [dl, setDl] = useState<number | null>(null)
  const end = useRef<HTMLDivElement>(null)
  useEffect(() => { end.current?.scrollIntoView({ behavior: 'smooth' }) }, [msgs])
  useEffect(() => {
    if (dl === null) return
    if (dl >= 100) { p.setModelReady(true); setDl(null); return }
    const t = setTimeout(() => setDl(dl + 10), 250)
    return () => clearTimeout(t)
  }, [dl])

  const chips = seller ? ['Anong kulang sa tindahan?', 'Mag-restock ng Lucky Me, good for 3 days', 'Ilan ang naibenta ko kahapon?', 'Ilista kay Aling Nena ang 120 pesos na utang'] : ['Kulang sa bahay', 'Nearby stores', 'Hanap: sardinas']

  const answer = (t: string): Msg => {
    const l = t.toLowerCase()
    if (!seller) {
      if (l.includes('kulang') || l.includes('nearby') || l.includes('hanap')) return { from: 'sari', risk: 'Read', text: 'Nahanap ko sa 3 malapit na tindahan: asin, toyo, sardinas at itlog. Handa na ang listahan. Ipadala sa tindahan?' }
      return { from: 'sari', risk: 'Read', text: 'Hindi ko po sigurado. Anong item at anong tindahan ang hanap ninyo?' }
    }
    if (/burahin|delete|i-?export|backup|settings/.test(l)) return { from: 'sari', risk: 'Blocked', text: 'Hindi ko po magagawa iyan. Para sa kaligtasan ng datos, sa Settings > Privacy and data po ito gagawin.' }
    if (l.includes('restock')) {
      const days = Number(/(\d+)\s*(days|araw)/.exec(l)?.[1] ?? 3)
      const wanted = l.includes('kape') || l.includes('kopiko') ? [1, 2] : [1]
      const lines = items.filter((i) => wanted.includes(i.id)).map((i) => needed(i, days)).filter(Boolean) as Line[]
      if (!lines.length) return { from: 'sari', risk: 'Read', text: `Sapat pa po ang stock para sa ${days} araw.` }
      const total = lines.reduce((s, x) => s + x.cost, 0)
      return { from: 'sari', risk: 'Draft', text: `Para sa ${days} araw, ito ang draft. Ang bilang ay galing sa reorder engine, hindi hula ng AI.`, draft: { kind: 'restock', title: 'Order draft', lines, total, note: 'Rounded up to pack size' }, state: 'open' }
    }
    if (l.includes('kulang')) {
      const low = items.filter((i) => i.stock < LOW)
      return { from: 'sari', risk: 'Read', text: low.length ? `${low.length} ang kulang: ${low.map((i) => `${i.name} (${i.stock})`).join(', ')}.` : 'Walang kulang ngayon.' }
    }
    if (l.includes('utang') || l.includes('ilista')) return { from: 'sari', risk: 'Draft', text: 'Ito ang draft ng ledger entry. Hindi pa naitatala.', draft: { kind: 'utang', title: 'Utang: Aling Nena', lines: [], total: 120, note: 'Ledger entry' }, state: 'open' }
    if (l.includes('kamatis') || l.includes('magkano')) { const kg = Number(/([\d.]+)\s*kilo/.exec(l)?.[1] ?? 1); return { from: 'sari', risk: 'Read', text: `${kg} kilo ng kamatis = ${peso(kg * 80)} (₱80/kilo). Ang halaga ay kinuwenta ng app, hindi ng AI.` } }
    if (l.includes('hula') || l.includes('forecast') || l.includes('predict') || l.includes('peak')) {
      return { from: 'sari', risk: 'Read', text: '🔮 Gemma 4 E2B & GBR Forecast: Inaasahang benta bukas ay ₱5,240.00 (🔥 PEAK DAY +38%). Payo: Mag-stock nang maaga sa Kopiko at Pancit Canton bago mag-alas 8 ng umaga.' }
    }
    if (l.includes('naibenta') || l.includes('sales') || l.includes('benta')) return { from: 'sari', risk: 'Read', text: 'Kahapon: ₱4,310 mula sa 58 benta. Top seller ang Kopiko 3-in-1 (212 pcs).' }
    if (l.includes('adobo') || l.includes('lutuin')) return storeType === 'Carenderia'
      ? { from: 'sari', risk: 'Draft', text: 'Prep suggestion para bukas, mula sa benta tuwing Huwebes at nasayang na ulam.', draft: { kind: 'prep', title: 'Prep list bukas', lines: [], total: 0, note: 'Adobo: 32 porsyon · Sinigang: 24 porsyon' } }
      : { from: 'sari', risk: 'Read', text: 'Para sa Carenderia store type po ito. Palitan sa Settings > Store.' }
    return { from: 'sari', risk: 'Read', text: 'Hindi ko po sigurado. Gusto ninyo bang i-restock, tingnan ang kulang, o ang benta?' }
  }

  const send = (t: string) => {
    if (!t.trim()) return
    const r = answer(t)
    setMsgs((m) => [...m, { from: 'me', text: t }, r])
    p.log({ tool: r.risk === 'Blocked' ? 'blocked' : r.draft ? `draft_${r.draft.kind}` : 'read_report', args: t.slice(0, 40), by: r.draft ? 'awaiting owner' : 'auto' })
    setText(''); setHeard(null)
    if (!seller && r.risk === 'Read' && /nahanap/i.test(r.text)) p.sentToStore(0)
  }
  const confirm = (i: number, d: Draft) => {
    if (d.kind !== 'prep' && d.total > limit && msgs[i].state === 'open') return setMsgs((m) => m.map((x, k) => (k === i ? { ...x, state: 'second' } : x)))
    setMsgs((m) => m.map((x, k) => (k === i ? { ...x, state: 'done' } : x)))
    p.onConfirm(d); p.log({ tool: `confirm_${d.kind}`, args: d.title, by: 'owner tap' })
    setTimeout(() => setMsgs((m) => m.map((x, k) => (k === i && x.state === 'done' ? { ...x, state: 'final' as never } : x))), 6000)
  }
  const undo = (i: number) => { setMsgs((m) => m.map((x, k) => (k === i ? { ...x, state: 'undone' } : x))); p.log({ tool: 'undo', args: 'draft', by: 'owner tap' }) }

  return (
    <div className="flex flex-col h-full">
      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {seller && !modelReady && (
          <Card className="bg-amber-soft! border-amber! pop">
            <p className="font-display font-bold text-amber flex items-center gap-2"><Download className="size-5" />Download model (isang beses lang)</p>
            <p className="text-sm my-1">Hindi pa handa ang AI model. Gumagana pa rin ang mga fixed phrase sa ibaba. Mag-download sa Wi-Fi, o kopyahin phone to phone.</p>
            {dl === null ? <button onClick={() => setDl(0)} className="min-h-12 px-5 rounded-2xl bg-amber text-white font-bold">Start download</button>
              : <div className="h-4 rounded-full bg-black/10 overflow-hidden"><div style={{ width: `${dl}%` }} className="h-full bg-amber transition-all" /></div>}
          </Card>
        )}
        {msgs.map((m, i) => (
          <div key={i} className={`pop flex ${m.from === 'me' ? 'justify-end' : 'justify-start'} gap-2`}>
            {m.from === 'sari' && <div className="size-9 shrink-0 rounded-full bg-amber text-white grid place-items-center"><Sparkles className="size-5" /></div>}
            <div className={`max-w-[84%] rounded-3xl px-4 py-3 text-[0.95rem] ${m.from === 'me' ? 'bg-brand text-white rounded-br-md' : 'bg-card border border-black/5 rounded-bl-md'}`}>
              {m.risk && <span className={`inline-block text-[0.65rem] font-extrabold uppercase tracking-wide rounded-full px-2 py-0.5 mb-1 ${RISK_STYLE[m.risk]}`}>{m.risk}</span>}
              <p>{m.text}</p>
              {m.draft && (
                <div className="mt-3 rounded-2xl bg-amber-soft border-2 border-amber p-3">
                  <p className="font-display font-bold text-amber">{m.draft.title} · draft pa lang</p>
                  {[...new Set(m.draft.lines.map((l) => l.supplier))].map((s) => (
                    <div key={s} className="mt-1"><p className="text-xs font-extrabold flex items-center gap-1"><Truck className="size-3.5" />{s}</p>
                      {m.draft!.lines.filter((l) => l.supplier === s).map((l) => <p key={l.id} className="text-sm">{l.name} × {l.qty} {l.unit}</p>)}</div>
                  ))}
                  {m.draft.note && <p className="text-xs mt-1 opacity-80">{m.draft.note}</p>}
                  {m.draft.total > 0 && <p className="font-display text-2xl font-extrabold">{peso(m.draft.total)}</p>}
                  {m.state === 'second' && <p className="text-sm font-bold text-brand flex items-center gap-1 mt-1"><AlertTriangle className="size-4" />Higit ito sa {peso(limit)}. Confirm ulit po?</p>}
                  {(m.state === 'open' || m.state === 'second') && (
                    <div className="flex gap-2 mt-2">
                      <button onClick={() => confirm(i, m.draft!)} className="flex-1 min-h-12 rounded-2xl bg-brand text-white font-bold">{m.state === 'second' ? 'Oo, confirm' : 'Confirm'}</button>
                      <button onClick={() => undo(i)} className="flex-1 min-h-12 rounded-2xl border-2 border-amber text-amber font-bold">Edit</button>
                    </div>)}
                  {(m.state as string) === 'done' && <div className="mt-2 flex items-center gap-2 text-sm font-bold text-brand"><Check className="size-5" />Na-confirm <button onClick={() => undo(i)} className="ml-auto min-h-10 px-3 rounded-xl bg-brand-soft flex items-center gap-1"><Undo2 className="size-4" />Undo</button></div>}
                  {(m.state as string) === 'final' && <div className="mt-2 flex gap-2 text-sm font-bold">{[[Share2, 'Share'], [Printer, 'Print'], [ListChecks, 'Checklist']].map(([Ic, l]) => { const I = Ic as LucideIcon; return <span key={l as string} className="flex items-center gap-1 bg-brand-soft text-brand rounded-xl px-3 min-h-10"><I className="size-4" />{l as string}</span> })}</div>}
                  {m.state === 'undone' && <p className="mt-2 text-sm font-bold opacity-70">Na-undo / hindi na itinuloy.</p>}
                </div>
              )}
              {!seller && /Handa na ang listahan/.test(m.text) && <button onClick={() => p.sentToStore(1)} className="mt-2 min-h-12 px-4 rounded-2xl bg-brand text-white font-bold flex items-center gap-2"><Send className="size-4" />Send to store</button>}
            </div>
          </div>
        ))}
        <div ref={end} />
      </div>
      {heard && (
        <div className="mx-3 mb-2 p-3 rounded-2xl bg-amber-soft border-2 border-amber pop">
          <p className="text-xs font-bold text-amber">Narinig ko:</p><p className="font-bold">"{heard}"</p>
          <div className="flex gap-2 mt-2"><button onClick={() => send(heard)} className="flex-1 min-h-12 rounded-2xl bg-brand text-white font-bold">Tama, gawin</button><button onClick={() => setHeard(null)} className="min-h-12 px-4 rounded-2xl border-2 border-amber text-amber font-bold"><X className="size-5" /></button></div>
        </div>)}
      <div className="px-3 pb-2 flex gap-2 overflow-x-auto">{chips.map((c) => <Chip key={c} onClick={() => send(c)}>{c}</Chip>)}</div>
      <form onSubmit={(e) => { e.preventDefault(); send(text) }} className="p-3 pt-1 flex gap-2 items-center">
        <input value={text} onChange={(e) => setText(e.target.value)} aria-label="Command" placeholder="Sabihin o i-type ang kailangan…" className="flex-1 min-h-12 rounded-full px-5 bg-card border-2 border-brand/25 focus:border-brand outline-none" />
        {modelReady && <button type="button" aria-label="Push to talk" onClick={() => { setListening(true); setTimeout(() => { setListening(false); setHeard(seller ? 'Mag-restock ng Lucky Me at kape, good for 3 days' : 'Kulang sa bahay') }, 1200) }} className={`size-12 rounded-full bg-amber text-white grid place-items-center ${listening ? 'bob ring-4 ring-amber/40' : ''}`}><Mic className="size-6" /></button>}
        <button aria-label="Send" className="size-12 rounded-full bg-brand text-white grid place-items-center"><Send className="size-5" /></button>
      </form>
    </div>
  )
}

/* ---------- LANDING ---------- */
function Landing({ onStart }: { onStart: (r: Role) => void }) {
  const feats: [LucideIcon, string][] = [
    [WifiOff, 'Gumagana kahit walang internet'],
    [Sparkles, 'Matalinong tulong, kayo pa rin ang masusunod'],
    [QrCode, 'Madaling order para sa tindahan at mamimili'],
  ]
  return (
    <div className="h-full overflow-y-auto bg-gradient-to-b from-[#8B1515] to-[#A31D1D] text-white flex flex-col items-center px-6 py-10 landing">
      <div className="w-22 h-22 rounded-3xl bg-white shadow-2xl flex items-center justify-center bob">
        <Store className="size-13 text-[#A31D1D]" />
      </div>
      <h1 className="font-display text-5xl font-extrabold mt-3.5 tracking-wider text-white">SARI</h1>
      <p className="text-center text-[#FDE8E8] text-sm mt-1">Ang tindahan ninyo, may kasamang katuwang.</p>
      <ul className="mt-6 space-y-2.5 w-full">
        {feats.map(([Ic, t], i) => (
          <li
            key={t}
            style={{ animationDelay: `${0.15 + i * 0.1}s` }}
            className="rise flex items-center gap-3 bg-[#6E1111]/50 border border-white/15 rounded-2xl px-4 min-h-13 text-sm font-semibold"
          >
            <Ic className="size-5 text-[#FFD54F] shrink-0" />
            <span>{t}</span>
          </li>
        ))}
      </ul>
      <div className="mt-auto pt-6 w-full space-y-3">
        <button
          onClick={() => onStart('buyer')}
          className="w-full min-h-14 rounded-full bg-white text-[#A31D1D] font-display text-base font-extrabold flex items-center justify-center gap-2 shadow-lg active:scale-[0.98] transition-all"
        >
          <ShoppingBag className="size-5" />
          Mamimili ako
        </button>
        <button
          onClick={() => onStart('seller')}
          className="w-full min-h-14 rounded-full bg-[#E5A93C] text-[#4A1800] font-display text-base font-extrabold flex items-center justify-center gap-2 shadow-lg active:scale-[0.98] transition-all"
        >
          <Store className="size-5" />
          May-ari ako ng tindahan
        </button>
        <p className="text-center text-xs text-[#FDE8E8]/70 pt-2">SARI · Lokal muna. Para sa lahat.</p>
      </div>
    </div>
  )
}

/* ---------- ORDER QR SCAN (seller) ---------- */
function OrderScanner({ order, onRead, onClose }: { order: BuyerOrder | null; onRead: (o: BuyerOrder) => void; onClose: () => void }) {
  const [res, setRes] = useState<'wait' | 'none'>('wait')
  useEffect(() => {
    const t = setTimeout(() => { if (order && order.status === 'Naipadala') onRead(order); else setRes('none') }, 1800)
    return () => clearTimeout(t)
  }, [])
  return (
    <div className="absolute inset-0 z-20 bg-ink/95 text-white flex flex-col pop">
      <div className="flex items-center p-3"><p className="flex-1 font-display text-xl font-bold flex items-center gap-2"><QrCode className="size-6 text-amber" />Scan order QR</p><button aria-label="Close" onClick={onClose} className="size-12 rounded-full bg-white/15 grid place-items-center"><X className="size-6" /></button></div>
      <div className="relative flex-1 mx-4 rounded-3xl bg-black/60 grid place-items-center overflow-hidden">
        <div className="relative size-56 rounded-3xl border-4 border-amber/90">
          {res === 'wait' && <div className="absolute inset-x-0 h-1 bg-amber shadow-[0_0_16px_var(--color-amber)] animate-[scan_1.2s_ease-in-out_infinite_alternate]" />}
        </div>
        <p className="absolute bottom-4 text-sm px-4 text-center">{res === 'wait' ? 'Ituro sa QR code ng buyer…' : 'Walang bagong order na na-scan. Ipakita ng buyer ang QR sa Profile > My orders.'}</p>
      </div>
      <div className="p-4"><button onClick={onClose} className="w-full min-h-14 rounded-2xl bg-white/15 font-bold">Isara</button></div>
    </div>
  )
}

/* ---------- INVENTORY ---------- */
function Inventory({ items, setItems, back }: { items: Item[]; setItems: React.Dispatch<React.SetStateAction<Item[]>>; back: () => void }) {
  const [q, setQ] = useState('')
  const [adding, setAdding] = useState(false)
  const [f, setF] = useState({ name: '', cat: 'Snacks', price: '', stock: '', supplier: 'Metro Supply' })
  const [flash, setFlash] = useState('')
  const set = (id: number, d: number) => setItems((it) => it.map((i) => (i.id === id ? { ...i, stock: Math.max(0, i.stock + d) } : i)))
  const valid = f.name.trim() && Number(f.price) > 0 && Number(f.stock) >= 0 && f.stock !== ''
  const add = (e: React.FormEvent) => {
    e.preventDefault()
    if (!valid) return
    const price = Number(f.price)
    setItems((it) => [{ id: Date.now(), name: f.name.trim(), price, cost: Math.round(price * 0.8 * 10) / 10, cat: f.cat, stock: Number(f.stock), perDay: 3, pack: 12, unit: 'pack', supplier: f.supplier }, ...it])
    setFlash(`Naidagdag: ${f.name.trim()}`); setF({ name: '', cat: 'Snacks', price: '', stock: '', supplier: 'Metro Supply' }); setAdding(false)
    setTimeout(() => setFlash(''), 2500)
  }
  const inp = 'w-full min-h-12 rounded-2xl px-4 bg-bg border-2 border-brand/25 focus:border-brand outline-none'
  const list = items.filter((i) => i.name.toLowerCase().includes(q.toLowerCase()))
  const value = items.reduce((s, i) => s + i.stock * i.cost, 0)
  return (
    <div className="p-4 space-y-3 overflow-y-auto h-full">
      <button onClick={back} className="flex items-center gap-1 font-bold text-brand min-h-10"><ArrowLeft className="size-5" />Bumalik sa POS</button>
      <div className="grid grid-cols-3 gap-2 text-center">{[['Produkto', String(items.length)], ['Kulang', String(items.filter((i) => i.stock < LOW).length)], ['Halaga ng stock', peso(value)]].map(([a, b]) => <Card key={a} className="p-3"><p className="text-[0.7rem] opacity-70">{a}</p><p className="font-display text-lg font-extrabold text-brand">{b}</p></Card>)}</div>
      {flash && <p className="pop text-center font-bold text-brand flex items-center justify-center gap-1"><Check className="size-5" />{flash}</p>}
      <button onClick={() => setAdding(!adding)} className="w-full min-h-14 rounded-2xl bg-brand text-white font-display font-bold text-lg flex items-center justify-center gap-2">{adding ? <X className="size-5" /> : <Plus className="size-5" />}{adding ? 'Isara' : 'Magdagdag ng produkto'}</button>
      {adding && (
        <form onSubmit={add} className="pop"><Card className="space-y-2">
          <input className={inp} placeholder="Pangalan ng produkto" value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} aria-label="Product name" />
          <div className="flex gap-2 overflow-x-auto">{CATS.slice(1).map((c) => <Chip key={c} active={f.cat === c} onClick={() => setF({ ...f, cat: c })}>{c}</Chip>)}</div>
          <div className="grid grid-cols-2 gap-2">
            <input className={inp} inputMode="decimal" placeholder="Presyo (₱)" value={f.price} onChange={(e) => setF({ ...f, price: e.target.value.replace(/[^\d.]/g, '') })} aria-label="Price" />
            <input className={inp} inputMode="numeric" placeholder="Stock" value={f.stock} onChange={(e) => setF({ ...f, stock: e.target.value.replace(/\D/g, '') })} aria-label="Stock" />
          </div>
          <input className={inp} placeholder="Supplier" value={f.supplier} onChange={(e) => setF({ ...f, supplier: e.target.value })} aria-label="Supplier" />
          <button disabled={!valid} className="w-full min-h-14 rounded-2xl bg-amber text-white font-bold disabled:opacity-40">I-save ang produkto</button>
        </Card></form>)}
      <label className="relative block"><Search className="absolute left-4 top-1/2 -translate-y-1/2 size-5 opacity-60" /><input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Hanapin sa inventory" className="w-full min-h-12 rounded-full pl-12 pr-4 bg-card border-2 border-brand/25 focus:border-brand outline-none" /></label>
      {list.map((i) => { const Ic = CAT_ICON[i.cat] ?? Package; return (
        <Card key={i.id} className="flex items-center gap-3 p-3">
          <Ic className="size-8 text-brand shrink-0" />
          <div className="flex-1 min-w-0"><p className="font-bold text-sm leading-tight">{i.name}</p><p className="text-xs opacity-70">{peso(i.price)} · {i.cat} · {i.supplier}</p>{i.stock < LOW && <p className="text-xs font-bold text-amber">Kulang na</p>}</div>
          <div className="flex items-center gap-1">
            <button aria-label="Bawasan" onClick={() => set(i.id, -1)} className="size-10 rounded-full bg-brand-soft text-brand grid place-items-center"><Minus className="size-5" /></button>
            <span className="w-9 text-center font-display font-extrabold">{i.stock}</span>
            <button aria-label="Dagdagan" onClick={() => set(i.id, 1)} className="size-10 rounded-full bg-brand text-white grid place-items-center"><Plus className="size-5" /></button>
          </div>
          <button aria-label="Burahin" onClick={() => setItems((it) => it.filter((x) => x.id !== i.id))} className="size-10 rounded-full grid place-items-center text-brand/70 hover:bg-brand-soft"><Trash2 className="size-5" /></button>
        </Card>) })}
    </div>
  )
}

/* ---------- AI SCAN (on-device detection, simulated) ---------- */
function Scanner({ items, onAdd, onClose }: { items: Item[]; onAdd: (i: Item) => void; onClose: () => void }) {
  const video = useRef<HTMLVideoElement>(null)
  const [found, setFound] = useState<{ item: Item; conf: number } | null>(null)
  const [round, setRound] = useState(0)
  const [cam, setCam] = useState(true)
  useEffect(() => {
    let stream: MediaStream | undefined
    navigator.mediaDevices?.getUserMedia({ video: { facingMode: 'environment' } }).then((s) => { stream = s; if (video.current) video.current.srcObject = s }).catch(() => setCam(false))
    return () => stream?.getTracks().forEach((t) => t.stop())
  }, [])
  useEffect(() => {
    setFound(null)
    const t = setTimeout(() => setFound({ item: items[Math.floor(Math.random() * items.length)], conf: 88 + Math.floor(Math.random() * 11) }), 2000)
    return () => clearTimeout(t)
  }, [round])
  const Ic = found ? CAT_ICON[found.item.cat] ?? Package : Camera
  return (
    <div className="absolute inset-0 z-20 bg-ink/95 text-white flex flex-col pop">
      <div className="flex items-center p-3"><p className="flex-1 font-display text-xl font-bold flex items-center gap-2"><ScanLine className="size-6 text-amber" />AI Scan</p><button aria-label="Close" onClick={onClose} className="size-12 rounded-full bg-white/15 grid place-items-center"><X className="size-6" /></button></div>
      <div className="relative flex-1 mx-4 rounded-3xl overflow-hidden bg-black/60 grid place-items-center">
        {cam ? <video ref={video} autoPlay playsInline muted className="absolute inset-0 size-full object-cover" /> : <Camera className="size-20 opacity-30" />}
        <div className="relative w-56 h-56 rounded-3xl border-4 border-amber/90">
          {!found && <div className="absolute inset-x-0 h-1 bg-amber shadow-[0_0_16px_var(--color-amber)] animate-[scan_1.4s_ease-in-out_infinite_alternate]" />}
          {found && <Ic className="size-24 absolute inset-0 m-auto text-amber pop" />}
        </div>
        <p className="absolute bottom-3 text-xs bg-black/50 rounded-full px-3 py-1 flex items-center gap-1"><WifiOff className="size-3" />Gumagana sa phone, walang internet{!cam && ' · walang camera'}</p>
      </div>
      <div className="p-4 min-h-44">
        {!found ? <p className="text-center font-bold animate-pulse pt-6">Tinitingnan ang produkto…</p> : (
          <div className="pop">
            <p className="text-xs opacity-70">Nakilala ({found.conf}% sigurado)</p>
            <p className="font-display text-2xl font-extrabold">{found.item.name}</p>
            <p className="text-amber font-display text-xl font-bold">{peso(found.item.price)}</p>
            <div className="flex gap-2 mt-3">
              <button onClick={() => onAdd(found.item)} className="flex-1 min-h-14 rounded-2xl bg-brand font-bold flex items-center justify-center gap-2"><Plus className="size-5" />Add to cart</button>
              <button onClick={() => setRound((r) => r + 1)} className="min-h-14 px-5 rounded-2xl bg-white/15 font-bold flex items-center gap-2"><RefreshCw className="size-5" />Ulit</button>
            </div>
            <button className="w-full min-h-12 mt-2 rounded-2xl border-2 border-white/30 font-bold text-sm">Mali? Turuan ang SARI gamit ang litrato</button>
          </div>)}
      </div>
    </div>
  )
}

/* ---------- POS ---------- */
function POS({ items, sell, order, claim, openInv }: { items: Item[]; sell: (c: Record<number, number>) => void; order: BuyerOrder | null; claim: () => void; openInv: () => void }) {
  const [cat, setCat] = useState('Lahat')
  const [q, setQ] = useState('')
  const [cart, setCart] = useState<Record<number, number>>({})
  const [pay, setPay] = useState('GCash')
  const [paid, setPaid] = useState('')
  const [hideNotice, setHideNotice] = useState(false)
  const count = Object.values(cart).reduce((a, b) => a + b, 0)
  const total = items.reduce((s, i) => s + i.price * (cart[i.id] || 0), 0)
  const list = items.filter((i) => (cat === 'Lahat' || i.cat === cat) && i.name.toLowerCase().includes(q.toLowerCase()))
  const add = (i: Item) => { if ((cart[i.id] || 0) < i.stock) { setPaid(''); setCart((c) => ({ ...c, [i.id]: (c[i.id] || 0) + 1 })) } }
  const press = useRef<number>(0)
  const [scan, setScan] = useState(false)
  const [qr, setQr] = useState(false)
  return (
    <div className="relative flex flex-col h-full bg-[#FAF7F2]">
      {qr && <OrderScanner order={order} onClose={() => setQr(false)} onRead={(o) => { setCart(Object.fromEntries(o.lines.map((l) => [l.id, l.qty]))); claim(); setPaid(`Order ${o.id} ni ${o.buyer} nai-load`); setQr(false) }} />}
      {scan && <Scanner items={items} onAdd={(i) => { add(i); setScan(false) }} onClose={() => setScan(false)} />}
      
      {/* Top Controls Area */}
      <div className="p-3 bg-white space-y-2 border-b border-black/5 shadow-sm">
        {/* Search input with trailing scan button */}
        <div className="relative flex items-center">
          <Search className="absolute left-3.5 size-5 text-black/40 pointer-events-none" />
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Hanapin ang produkto"
            className="w-full min-h-11 rounded-full pl-11 pr-12 bg-white border border-[#DDD5CE] text-sm text-black focus:border-[#A31D1D] outline-none shadow-xs"
          />
          <button
            onClick={() => setScan(true)}
            aria-label="Scan barcode"
            className="absolute right-1.5 size-8 rounded-full bg-[#FDE8E8] text-[#A31D1D] grid place-items-center active:scale-95"
          >
            <QrCode className="size-4" />
          </button>
        </div>

        {/* Action pills: Imbentaryo, SCAN, AI Scan */}
        <div className="grid grid-cols-3 gap-2">
          <button
            onClick={openInv}
            className="min-h-9 rounded-full bg-white border border-[#DDD5CE] text-[#5A4A42] font-bold text-xs flex items-center justify-center gap-1.5 hover:bg-black/5"
          >
            <Boxes className="size-3.5 text-[#5A4A42]" />
            Imbentaryo
          </button>
          <button
            onClick={() => setQr(true)}
            className="min-h-9 rounded-full bg-[#A31D1D] text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-xs"
          >
            <QrCode className="size-3.5" />
            SCAN
          </button>
          <button
            onClick={() => setScan(true)}
            className="min-h-9 rounded-full bg-blue-600 text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-xs"
          >
            <ScanLine className="size-3.5" />
            AI SCAN
          </button>
        </div>

        {/* Horizontal Category Chips (Image 1) */}
        <div className="flex gap-2 overflow-x-auto pt-0.5 pb-0.5 no-scrollbar">
          {CATS.map((c) => {
            const isSel = cat === c
            return (
              <button
                key={c}
                onClick={() => setCat(c)}
                className={`min-h-8 px-3.5 rounded-full text-xs font-bold shrink-0 transition-all flex items-center gap-1 border ${
                  isSel
                    ? 'bg-[#FDE8E8] text-[#8B1515] border-[#E5B8B8] font-extrabold'
                    : 'bg-white text-black/80 border-[#DDD5CE]'
                }`}
              >
                {isSel && <Check className="size-3 stroke-[3]" />}
                {c}
              </button>
            )
          })}
        </div>
      </div>

      {/* Main Content: Responsive Product Blocks Grid */}
      <div className="flex-1 overflow-y-auto p-3 grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2.5 content-start">
        {list.map((i) => {
          const Ic = CAT_ICON[i.cat] ?? Package
          const inCart = cart[i.id]
          const isLow = i.stock < LOW
          return (
            <button
              key={i.id}
              onClick={() => add(i)}
              onPointerDown={() => (press.current = Date.now())}
              className={`relative bg-white rounded-2xl p-3 border shadow-xs text-left flex flex-col justify-between min-h-32 transition-all active:scale-[0.98] ${
                inCart ? 'border-[#E5A93C] ring-1 ring-[#E5A93C]' : 'border-[#ECE7E2] hover:border-[#A31D1D]/30'
              }`}
            >
              {/* Top row: Category icon + In-cart amber badge */}
              <div className="flex items-center justify-between w-full">
                <Ic className="size-5 text-[#A31D1D]" />
                {inCart ? (
                  <span className="size-5 rounded-full bg-[#E5A93C] text-white text-[0.7rem] font-black grid place-items-center pop">
                    {inCart}
                  </span>
                ) : (
                  <span className="size-5" />
                )}
              </div>

              {/* Name */}
              <div className="text-xs font-bold text-black/85 leading-tight line-clamp-2 mt-2">
                {i.name}
              </div>

              {/* Bottom: Price and Stock */}
              <div className="mt-1.5">
                <div className="font-display font-black text-base text-[#A31D1D] leading-none">
                  {peso(i.price)}
                </div>
                {isLow ? (
                  <div className="text-[0.65rem] font-bold text-[#A31D1D] mt-0.5">
                    Natitira {i.stock}
                  </div>
                ) : (
                  <div className="text-[0.65rem] text-black/50 mt-0.5">
                    Stock {i.stock}
                  </div>
                )}
              </div>
            </button>
          )
        })}
      </div>

      {/* Sticky Bottom Checkout Dock (Image 1) */}
      <div className="p-3.5 bg-white border-t border-black/10 rounded-t-3xl shadow-2xl space-y-2">
        {/* Offline Notice */}
        {!hideNotice && (
          <div className="flex items-center gap-1.5 text-[0.7rem] text-black/80">
            <span className="text-[#A31D1D] text-xs font-black">ⓘ</span>
            <span className="flex-1">Sa device na ito naka-save ang mga benta</span>
            <button
              onClick={() => setHideNotice(true)}
              className="text-black/50 hover:text-black font-semibold text-xs"
            >
              Alisin
            </button>
          </div>
        )}

        {paid && (
          <p className="pop text-center font-bold text-xs text-[#A31D1D] flex items-center justify-center gap-1">
            <Check className="size-4" />
            {paid}
          </p>
        )}

        {/* Payment Methods Segmented Pills (Cash, GCash, Utang) */}
        <div className="grid grid-cols-3 gap-2">
          {['Cash', 'GCash', 'Utang'].map((x) => {
            const isSel = pay === x
            return (
              <button
                key={x}
                onClick={() => setPay(x)}
                className={`min-h-9 rounded-full text-xs font-bold border transition-all flex items-center justify-center gap-1 ${
                  isSel
                    ? 'bg-[#FDE8E8] text-[#8B1515] border-[#E5B8B8] font-extrabold'
                    : 'bg-white text-black/80 border-[#DDD5CE]'
                }`}
              >
                {isSel && <Check className="size-3 stroke-[3]" />}
                {x}
              </button>
            )
          })}
        </div>

        {/* Summary row */}
        <div className="flex items-center justify-between pt-1">
          <div>
            <p className="text-[0.7rem] text-black/55 font-semibold leading-none">{count} item</p>
            <p className="font-display text-2xl font-black text-black leading-tight mt-0.5">{peso(total)}</p>
          </div>
          <button
            disabled={!count}
            onClick={() => {
              sell(cart)
              setPaid(`Bayad na (${pay}) · ${peso(total)}`)
              setCart({})
            }}
            className="min-h-12 px-8 rounded-full bg-[#A31D1D] text-white font-display font-black text-base disabled:opacity-40 shadow-md active:scale-95 transition-all"
          >
            Bayaran
          </button>
        </div>
      </div>
    </div>
  )
}

/* ---------- PREDICTIVE INSIGHTS (seasonal baseline forecast, simulated data) ---------- */
const DAYS = ['Lun', 'Mar', 'Miy', 'Huw', 'Biy', 'Sab', 'Lin']
const WEEK_PATTERN = [0.82, 0.8, 0.88, 0.95, 1.2, 1.3, 1.05]
function Insights({ items, goAgent }: { items: Item[]; goAgent: () => void }) {
  const [sel, setSel] = useState(1)
  const it = items.find((i) => i.id === sel)!
  const fc = WEEK_PATTERN.map((w) => Math.round(it.perDay * w))
  const max = Math.max(...fc)
  const outDay = Math.max(0, Math.floor(it.stock / it.perDay))
  const market: [string, number, string][] = [['Bigas (sako)', 6.4, 'Tataas pa sa susunod na linggo (anihan: late)'], ['Itlog (tray)', -3.1, 'Bumababa ang presyo sa supplier'], ['Mantika (1L)', 4.2, 'Mahal ang import ngayong buwan'], ['Kamatis (kilo)', -8.5, 'Maraming ani, mura ang bili']]
  const tips: [LucideIcon, string, string][] = [
    [CalendarDays, 'Sweldo sa 15 at 30', 'Tataas ng ~35% ang benta ng noodles, kape at sabon. Mag-stock 2 araw bago.'],
    [Flame, 'Mainit na panahon', 'Inaasahang +22% sa softdrinks at yelo ngayong weekend.'],
    [Tag, 'Presyo', 'Puwedeng itaas ang Piattos ng ₱1: mabilis ang benta at hindi nagbago ang demand ng kapitbahay na tindahan.'],
    [Percent, 'Bundle', 'Madalas sabay mabili ang Lucky Me + Kopiko (41% ng benta). Gawing ₱22 na combo.'],
    [Lightbulb, 'Dead stock', 'Surf Sachet: 60 pcs, mabagal ang benta. Huwag munang mag-order.'],
  ]
  return (
    <div className="space-y-3">
      <p className="font-display font-bold text-lg flex items-center gap-2"><TrendingUp className="size-5 text-brand" />Predictive AI</p>
      <Card>
        <p className="font-bold text-sm">Forecast sa susunod na 7 araw</p>
        <div className="flex gap-2 overflow-x-auto my-2">{items.slice(0, 6).map((i) => <Chip key={i.id} active={sel === i.id} onClick={() => setSel(i.id)}>{i.name.split(' ')[0]}</Chip>)}</div>
        <div className="flex items-end gap-1.5 h-24">{fc.map((v, i) => (
          <div key={i} className="flex-1 flex flex-col items-center justify-end h-full gap-1"><span className="text-[0.65rem] font-bold">{v}</span>
            <div style={{ height: `${(v / max) * 70}%` }} className={`w-full rounded-t-lg ${i === outDay ? 'bg-amber' : 'bg-brand'} hover:opacity-80`} /><span className="text-[0.65rem] opacity-70">{DAYS[i]}</span></div>))}</div>
        <p className="text-sm mt-2"><b>{it.name}</b>: ubos sa loob ng <b>{outDay || '<1'} araw</b> kung ganito ang benta. Kailangan ng ~{fc.reduce((a, b) => a + b, 0)} pcs ngayong linggo.</p>
        <p className="text-xs opacity-70">Kumpiyansa 84% · seasonal baseline, gagaling habang dumarami ang history</p>
        <button onClick={goAgent} className="mt-2 min-h-12 px-4 rounded-2xl bg-amber text-white font-bold text-sm">I-draft ang restock</button>
      </Card>
      <Card>
        <p className="font-bold text-sm mb-2">Presyo sa merkado (supplier)</p>
        {market.map(([n, c, note]) => (
          <div key={n} className="flex items-center gap-3 py-2 border-b border-black/5 last:border-0">
            <span className={`size-9 rounded-full grid place-items-center ${c > 0 ? 'bg-brand-soft text-brand' : 'bg-amber-soft text-amber'}`}>{c > 0 ? <ArrowUp className="size-5" /> : <ArrowDown className="size-5" />}</span>
            <div className="flex-1"><p className="font-bold text-sm">{n} <span className="font-extrabold">{c > 0 ? '+' : ''}{c}%</span></p><p className="text-xs opacity-70">{note}</p></div>
          </div>))}
      </Card>
      <Card>
        <p className="font-bold text-sm mb-2">Mga mungkahi ng SARI</p>
        {tips.map(([Ic, t, d]) => (
          <div key={t} className="flex gap-3 py-2 border-b border-black/5 last:border-0"><Ic className="size-6 text-amber shrink-0" /><div><p className="font-bold text-sm">{t}</p><p className="text-xs opacity-80">{d}</p></div></div>))}
      </Card>
      <Card className="grid grid-cols-2 gap-3 text-center">
        {[['Inaasahang benta bukas', '₱5,240'], ['Inaasahang kita (linggo)', '₱6,780'], ['Pinakamalakas na araw', 'Sabado'], ['Panganib na ubos', `${items.filter((i) => i.stock / i.perDay < 1.5).length} item`]].map(([a, b]) => <div key={a}><p className="text-xs opacity-70">{a}</p><p className="font-display text-xl font-extrabold text-brand">{b}</p></div>)}
      </Card>
    </div>
  )
}

/* ---------- DATA SUMMARY ---------- */
function Summary({ items, storeType, goAgent, orders, receive }: { items: Item[]; storeType: StoreType; goAgent: () => void; orders: Draft[]; receive: (l: Line) => void }) {
  const [range, setRange] = useState('Today')
  const [got, setGot] = useState<number[]>([])
  const sales = { Today: 4820, Week: 31450, Month: 128900 }[range as 'Today']
  const bars = [40, 55, 35, 70, 60, 85, 95]
  const last = orders[orders.length - 1]
  return (
    <div className="p-4 space-y-3 overflow-y-auto h-full">
      <div className="flex gap-2">{['Today', 'Week', 'Month'].map((r) => <Chip key={r} active={range === r} onClick={() => setRange(r)}>{r}</Chip>)}</div>
      <Card className="bg-brand! text-white">
        <p className="text-sm opacity-90 flex items-center gap-1"><TrendingUp className="size-4" />Benta · Sales ({storeType})</p>
        <p className="font-display text-5xl font-extrabold">{peso(sales)}</p>
        <div className="flex items-end gap-1.5 h-14 mt-3">{bars.map((b, i) => <div key={i} style={{ height: `${b}%` }} className="flex-1 rounded-t-lg bg-white/70 hover:bg-amber transition-colors" />)}</div>
      </Card>
      <div className="grid grid-cols-3 gap-2">
        {[[Boxes, 'Low stock', `${items.filter((i) => i.stock < LOW).length} item`], [Wallet, 'Utang to collect', '₱1,240'], [Trophy, 'Top seller', 'Kopiko']].map(([I, a, b]) => { const Ic = I as LucideIcon; return (
          <Card key={a as string} className="text-center p-3"><Ic className="size-6 mx-auto text-brand" /><p className="text-[0.7rem] opacity-70">{a as string}</p><p className="font-display font-extrabold leading-tight">{b as string}</p></Card>) })}
      </div>
      {last && last.lines.length > 0 && (
        <Card><p className="font-display font-bold text-lg flex items-center gap-2"><ClipboardList className="size-5 text-brand" />Receive stock</p>
          <p className="text-xs opacity-70 mb-2">I-tap ang dumating na. Mag-u-update ang inventory.</p>
          {last.lines.map((l) => <button key={l.id} disabled={got.includes(l.id)} onClick={() => { setGot((g) => [...g, l.id]); receive(l) }} className="w-full flex items-center gap-3 min-h-12 px-3 mb-1 rounded-xl bg-brand-soft font-bold text-left disabled:opacity-50">
            <span className={`size-6 rounded-md border-2 border-brand grid place-items-center ${got.includes(l.id) ? 'bg-brand' : ''}`}>{got.includes(l.id) && <Check className="size-4 text-white" />}</span>{l.name} × {l.qty} {l.unit}</button>)}
        </Card>)}
      <p className="font-display font-bold text-lg">Restock suggestions</p>
      {items.filter((i) => i.stock < LOW).map((i) => { const Ic = CAT_ICON[i.cat] ?? Package; const days = (i.stock / i.perDay).toFixed(1); return (
        <Card key={i.id} className="flex items-center gap-3 p-3">
          <Ic className="size-8 text-brand shrink-0" />
          <div className="flex-1 min-w-0"><p className="font-bold text-sm">{i.name}</p><p className="text-xs text-amber font-bold">{i.stock} na lang · ubos sa loob ng {days} araw</p></div>
          <button onClick={goAgent} className="min-h-12 px-4 rounded-2xl bg-amber text-white font-bold text-sm">Draft</button>
        </Card>) })}
      <Insights items={items} goAgent={goAgent} />
      <button onClick={() => { const t = `SARI report\nBenta (${range}): ${peso(sales)}\nLow stock: ${items.filter((i) => i.stock < LOW).map((i) => i.name).join(', ')}\n`; const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([t], { type: 'text/plain' })); a.download = 'sari-report.txt'; a.click() }} className="w-full min-h-14 rounded-2xl bg-brand text-white font-bold flex items-center justify-center gap-2"><FileText className="size-5" />I-export ang report</button>
    </div>
  )
}

/* ---------- PROFILE / INBOX ---------- */
function Profile({ role, order, verify }: { role: Role; order: BuyerOrder | null; verify: Verify }) {
  return (
    <div className="p-4 space-y-2 overflow-y-auto h-full">
      <Card className="text-center">
        <div className="size-24 rounded-full bg-brand-soft mx-auto grid place-items-center bob"><User className="size-12 text-brand" /></div>
        <p className="font-display text-2xl font-extrabold mt-2">{role === 'buyer' ? 'Juan Dela Cruz' : 'Nena Reyes'}</p>
        <p className="text-sm opacity-70 flex items-center justify-center gap-1"><MapPin className="size-4" />Brgy. Poblacion, Batangas City</p>
      </Card>
      {verify.status === 'ok' ? <p className="flex items-center gap-2 font-bold text-brand bg-brand-soft rounded-2xl px-4 min-h-12"><BadgeCheck className="size-6" />Verified ng eGov · {verify.idMasked}</p> : <p className="flex items-center gap-2 font-bold text-amber bg-amber-soft rounded-2xl px-4 min-h-12"><AlertTriangle className="size-5" />Hindi pa verified · Settings &gt; Account</p>}
      <p className="font-display font-bold text-lg pt-1">My orders</p>
      {order ? (
        <Card className="pop text-center">
          <p className="font-bold">Order {order.id} · {order.store}</p>
          <div className="bg-white p-3 rounded-2xl inline-block my-2 shadow-sm"><QRCodeSVG value={JSON.stringify({ o: order.id, s: order.store, b: order.buyer, l: order.lines.map((l) => [l.id, l.qty]), t: order.total })} size={176} fgColor="#8e1616" level="M" /></div>
          <p className="text-sm opacity-80">Ipakita ang QR na ito sa tindera para ma-scan.</p>
          <div className="text-left text-sm mt-2">{order.lines.map((l) => <p key={l.id} className="flex justify-between"><span>{l.name} × {l.qty}</span><span>{peso(l.price * l.qty)}</span></p>)}</div>
          <p className="font-display text-2xl font-extrabold mt-1">{peso(order.total)}</p>
          <span className={`inline-block mt-1 rounded-full px-3 py-1 text-xs font-extrabold ${order.status === 'Na-scan' ? 'bg-brand text-white' : 'bg-amber-soft text-amber'}`}>{order.status}</span>
        </Card>) : <Card className="text-center text-sm opacity-80">Wala pang order. Sa AI Agent, hanapin ang kailangan at pindutin ang "Send to store".</Card>}
      <Row icon={Wallet} label="Utang balance" sub="₱120 · read-only" />
      <Row icon={Heart} label="Saved stores" /><Row icon={Home} label="Addresses" /><Row icon={Lock} label="Settings" />
    </div>
  )
}
function Inbox({ order }: { order: BuyerOrder | null }) {
  const [tab, setTab] = useState('Messages')
  const data: Record<string, [LucideIcon, string, string, string, number][]> = {
    Messages: [...(order ? [[Store, 'Aling Nena Store', 'Natanggap ang order ninyo. Ipakita ang QR pagdating!', 'Ngayon', 1] as [LucideIcon, string, string, string, number]] : []), [Store, 'Kuya Gulay', 'Sariwa po ang petsay ngayon', '1h', 0]],
    Orders: [...(order ? [[Package, `Order ${order.id}`, order.status === 'Na-scan' ? 'Na-scan na sa tindahan' : 'Naipadala, hintayin ang scan', 'Ngayon', 1] as [LucideIcon, string, string, string, number]] : []), [Package, 'Order #1042', 'Handa na po ang order', '5m', 0], [Package, 'Order #1038', 'Natanggap na', 'Kahapon', 0]],
    Alerts: [[Bell, 'Presyo', 'Bumaba ang presyo ng itlog sa Aling Nena', '10m', 1]],
  }
  return (
    <div className="p-4 space-y-3 overflow-y-auto h-full">
      <label className="relative block"><Search className="absolute left-4 top-1/2 -translate-y-1/2 size-5 opacity-60" /><input placeholder="Search" className="w-full min-h-12 rounded-full pl-12 pr-4 bg-card border-2 border-brand/25 focus:border-brand outline-none" /></label>
      <div className="flex gap-2">{Object.keys(data).map((t) => <Chip key={t} active={tab === t} onClick={() => setTab(t)}>{t}</Chip>)}</div>
      {data[tab].map(([Ic, n, m, t, u]) => (
        <Card key={n} className="flex items-center gap-3 p-3 pop">
          <div className="size-12 rounded-full bg-brand-soft grid place-items-center"><Ic className="size-6 text-brand" /></div>
          <div className="flex-1 min-w-0"><p className="font-bold">{n}</p><p className="text-sm opacity-70 truncate">{m}</p></div>
          <div className="text-right text-xs opacity-70">{t}{u > 0 && <span className="block mt-1 ml-auto size-6 rounded-full bg-amber text-white font-bold grid place-items-center">{u}</span>}</div>
        </Card>))}
    </div>
  )
}

/* ---------- SETTINGS ---------- */
function Toggle({ icon: Icon, label, on, set }: { icon: LucideIcon; label: string; on: boolean; set: (v: boolean) => void }) {
  return (
    <button onClick={() => set(!on)} role="switch" aria-checked={on} className="w-full flex items-center gap-3 min-h-14 px-4 rounded-2xl bg-card border border-black/5 font-bold text-left">
      <Icon className="size-6 text-brand shrink-0" /><span className="flex-1">{label}</span>
      <span className={`w-14 h-8 rounded-full p-1 flex ${on ? 'bg-brand justify-end' : 'bg-black/25 justify-start'}`}><span className="size-6 rounded-full bg-white" /></span>
    </button>
  )
}
const H = ({ children, amber }: { children: React.ReactNode; amber?: boolean }) => <p className={`font-display font-bold text-lg pt-3 ${amber ? 'text-amber' : ''}`}>{children}</p>
function Settings(p: { verify: Verify; setVerify: (v: Verify) => void; openInv: () => void; role: Role; dark: boolean; setDark: (v: boolean) => void; large: boolean; setLarge: (v: boolean) => void; storeType: StoreType; setStoreType: (s: StoreType) => void; modelReady: boolean; setModelReady: (v: boolean) => void; limit: number; setLimit: (n: number) => void; logs: Log[] }) {
  const [voice, setVoice] = useState(true)
  const [ask, setAsk] = useState(true)
  const [wifi, setWifi] = useState(true)
  const [share, setShare] = useState(false)
  const [lang, setLang] = useState('Taglish')
  const [showLog, setShowLog] = useState(false)
  const seller = p.role === 'seller'
  return (
    <div className="p-4 space-y-2 overflow-y-auto h-full">
      <H>Account</H>
      <Row icon={User} label={seller ? 'Nena Reyes · Seller' : 'Juan Dela Cruz · Buyer'} sub="Phone, photo, PIN or fingerprint lock" />
      <EgovVerify verify={p.verify} setVerify={p.setVerify} />
      {seller && <><H>Store</H>
        <div className="flex gap-2 overflow-x-auto pb-1">{(['Sari-sari', 'Gulay', 'Rice', 'Carenderia'] as StoreType[]).map((s) => <Chip key={s} active={p.storeType === s} onClick={() => p.setStoreType(s)}>{s}</Chip>)}</div>
        <Row icon={Boxes} label="Inventory at mga produkto" sub="Magdagdag, i-edit ang stock" onClick={p.openInv} /><Row icon={Truck} label="Suppliers" sub="Metro Supply, Lipa Rice Mill, +2" /><Row icon={Boxes} label={`Low-stock level · ${LOW}`} /><Row icon={Printer} label="Receipt and printer" /><Row icon={Wallet} label="Payment types" sub="Cash, GCash, Utang" /><Row icon={ShieldCheck} label="Staff and PIN" /></>}
      <H amber>AI Agent</H>
      <Card className="bg-amber-soft! border-amber! text-sm flex items-center justify-between gap-2">
        <span><b>Gemma 4 E2B</b> · {p.modelReady ? 'Ready' : 'Not downloaded'}<br /><span className="opacity-70">Walang network call sa agent path</span></span>
        <button onClick={() => p.setModelReady(!p.modelReady)} className="min-h-12 px-3 rounded-xl bg-amber text-white font-bold shrink-0">{p.modelReady ? 'Unload' : 'Load'}</button>
      </Card>
      <Toggle icon={Mic} label="Voice input" on={voice} set={setVoice} />
      <Toggle icon={ShieldCheck} label="Ask before every change" on={ask} set={setAsk} />
      <Toggle icon={WifiOff} label="Download on Wi-Fi only" on={wifi} set={setWifi} />
      <Toggle icon={Repeat} label="Nearby model sharing" on={share} set={setShare} />
      {seller && <div className="flex items-center gap-3 min-h-14 px-4 rounded-2xl bg-card border border-black/5 font-bold"><AlertTriangle className="size-6 text-brand" /><span className="flex-1 text-sm">Second confirm above</span>
        {[1000, 2000, 5000].map((n) => <button key={n} onClick={() => p.setLimit(n)} className={`min-h-10 px-3 rounded-xl text-sm ${p.limit === n ? 'bg-brand text-white' : 'bg-brand-soft text-brand'}`}>{peso(n)}</button>)}</div>}
      <Row icon={ClipboardList} label="Agent activity log" sub="Bakit ito ang iminungkahi?" onClick={() => setShowLog(!showLog)} />
      {showLog && <Card className="text-xs space-y-1 pop">{p.logs.length ? p.logs.map((l, i) => <p key={i}><b>{l.t}</b> · {l.tool} · "{l.args}" · {l.by}</p>) : 'Wala pang activity.'}</Card>}
      <H>Language</H>
      <div className="flex gap-2 overflow-x-auto">{['Taglish', 'Filipino', 'English'].map((l) => <Chip key={l} active={lang === l} onClick={() => setLang(l)}><Languages className="size-4 inline mr-1" />{l}</Chip>)}</div>
      <H>Display</H>
      <Toggle icon={Moon} label="Dark mode" on={p.dark} set={p.setDark} />
      <Toggle icon={Type} label="Malaking letra (Large text)" on={p.large} set={p.setLarge} />
      <H>Privacy and data</H>
      <Row icon={Ban} label="Backup, export, delete history" sub="Hindi ito magagawa ng AI agent" />
      <H>About SARI</H>
      <Row icon={ShieldCheck} label="Version 1.0 · Licenses (Gemma terms) · Help" />
    </div>
  )
}

/* ---------- EGOV VERIFICATION ---------- */
// Swap this stub for the real eGov / PhilSys endpoint call (needs government-issued API credentials).
async function verifyEgov(id: string): Promise<boolean> {
  await new Promise((r) => setTimeout(r, 1600))
  return id.length === 12 || id.length === 16
}
function EgovVerify({ verify, setVerify }: { verify: Verify; setVerify: (v: Verify) => void }) {
  const [id, setId] = useState('')
  const [open, setOpen] = useState(false)
  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    const d = id.replace(/\D/g, '')
    setVerify({ status: 'pending' })
    const ok = await verifyEgov(d)
    setVerify(ok ? { status: 'ok', idMasked: '•••• ' + d.slice(-4) } : { status: 'fail' })
  }
  if (verify.status === 'ok') return <Card className="flex items-center gap-3 bg-brand-soft! pop"><BadgeCheck className="size-9 text-brand" /><div className="flex-1"><p className="font-display font-bold text-brand">Verified ng eGov</p><p className="text-xs opacity-80">PhilSys / UMID {verify.idMasked} · may Trust badge na</p></div></Card>
  return (
    <Card className="space-y-2">
      <button onClick={() => setOpen(!open)} className="w-full flex items-center gap-3 text-left min-h-12"><ShieldCheck className="size-7 text-amber" /><span className="flex-1"><b>I-verify ang account (eGov)</b><span className="block text-xs opacity-70">Para sa Trust badge at mas ligtas na order</span></span><ChevronRight className={`size-5 transition-transform ${open ? 'rotate-90' : ''}`} /></button>
      {open && (
        <form onSubmit={submit} className="space-y-2 pop">
          <input value={id} onChange={(e) => setId(e.target.value.replace(/[^\d-]/g, ''))} inputMode="numeric" placeholder="PhilSys ID (16) o UMID (12 digits)" aria-label="ID number" className="w-full min-h-12 rounded-2xl px-4 bg-bg border-2 border-brand/25 focus:border-brand outline-none" />
          <button disabled={verify.status === 'pending' || id.replace(/\D/g, '').length < 12} className="w-full min-h-12 rounded-2xl bg-brand text-white font-bold disabled:opacity-50 flex items-center justify-center gap-2">{verify.status === 'pending' ? <><Loader2 className="size-5 animate-spin" />Kinukumpirma sa eGov…</> : 'I-verify'}</button>
          {verify.status === 'fail' && <p className="text-sm font-bold text-brand flex items-center gap-1"><AlertTriangle className="size-4" />Hindi tugma ang ID. Tingnan ang numero at subukan ulit.</p>}
          <p className="text-[0.7rem] opacity-60">Demo: tumatanggap ng 12 o 16 na digit. Ang tunay na eGov API ay kailangang ikabit sa verifyEgov().</p>
        </form>)}
    </Card>
  )
}

/* ---------- SHELL ---------- */
export default function App() {
  const [started, setStarted] = useState(false)
  const [verify, setVerify] = useState<Verify>({ status: 'none' })
  const [order, setOrder] = useState<BuyerOrder | null>(null)
  const dirRef = useRef<{ prev: number; dir: 'r' | 'l' }>({ prev: 0, dir: 'r' })
  const [role, setRole] = useState<Role>('seller')
  const [tab, setTab] = useState<Tab>('agent')
  const [dark, setDark] = useState(false)
  const [large, setLarge] = useState(false)
  const [items, setItems] = useState(INITIAL)
  const [storeType, setStoreType] = useState<StoreType>('Sari-sari')
  const [modelReady, setModelReady] = useState(true)
  const [limit, setLimit] = useState(2000)
  const [logs, setLogs] = useState<Log[]>([])
  const [orders, setOrders] = useState<Draft[]>([])
  const [sent, setSent] = useState(0)
  useEffect(() => { document.documentElement.classList.toggle('dark', dark) }, [dark])
  useEffect(() => { document.documentElement.classList.toggle('large', large) }, [large])

  const ORDER: Tab[] = ['agent', 'center', 'right', 'settings', 'inventory']
  const idx = ORDER.indexOf(tab)
  if (idx !== dirRef.current.prev) { dirRef.current = { prev: idx, dir: idx > dirRef.current.prev ? 'r' : 'l' } }
  const sendOrder = () => {
    const pick: [number, number][] = [[5, 6], [2, 4], [1, 2]]
    const lines = pick.map(([id, qty]) => { const i = INITIAL.find((x) => x.id === id)!; return { id, name: i.name, qty, price: i.price } })
    setOrder({ id: '#SARI-' + (1043 + Math.floor(Math.random() * 50)), store: 'Aling Nena Store', buyer: 'Juan', lines, total: lines.reduce((s, l) => s + l.price * l.qty, 0), status: 'Naipadala' })
  }
  const seller = role === 'seller'
  const nav: { id: Tab; icon: LucideIcon; label: string }[] = [
    { id: 'agent', icon: Sparkles, label: 'AI Agent' },
    { id: 'center', icon: seller ? ShoppingCart : User, label: seller ? 'POS' : 'Profile' },
    { id: 'right', icon: seller ? BarChart3 : MessageCircle, label: seller ? 'Data Summary' : 'Inbox' },
  ]
  const title = tab === 'settings' ? 'Settings' : tab === 'inventory' ? 'Inventory' : nav.find((n) => n.id === tab)!.label

  return (
    <div className="min-h-dvh grid place-items-center sm:p-6 bg-[radial-gradient(circle_at_15%_10%,var(--color-brand-soft),transparent_50%),radial-gradient(circle_at_90%_90%,var(--color-amber-soft),transparent_45%)]">
      <div className="w-full sm:max-w-[420px] h-dvh sm:h-[860px] sm:max-h-[calc(100dvh-3rem)] bg-bg flex flex-col sm:rounded-[2.5rem] overflow-hidden shadow-2xl sm:border-8 border-ink/90">
        {!started ? <Landing onStart={(r) => { setRole(r); setTab('agent'); setStarted(true) }} /> : <>
        <header className="bg-brand text-white px-4 py-3 flex items-center gap-3">
          <Logo size={44} />
          <div className="flex-1 min-w-0">
            <h1 className="font-display text-2xl font-extrabold leading-none">{title}</h1>
            <button onClick={() => { setRole(seller ? 'buyer' : 'seller'); setTab('agent') }} className="text-xs font-bold bg-white/20 rounded-full px-3 min-h-8 mt-1 flex items-center gap-1"><Repeat className="size-3" />{seller ? 'Seller' : 'Buyer'} · palitan</button>
          </div>
          <button aria-label="Account and settings" onClick={() => setTab('settings')} className="size-12 rounded-full bg-white text-brand font-display font-extrabold text-xl grid place-items-center ring-2 ring-white/50">{seller ? 'N' : 'J'}</button>
        </header>
        <main key={tab + role} className={`flex-1 min-h-0 ${dirRef.current.dir === 'r' ? 'slide-r' : 'slide-l'}`}>
          {tab === 'agent' && <Agent role={role} items={items} storeType={storeType} modelReady={modelReady} setModelReady={setModelReady} limit={limit}
            log={(l) => setLogs((x) => [{ ...l, t: new Date().toLocaleTimeString('en-PH', { hour: '2-digit', minute: '2-digit' }) }, ...x])}
            onConfirm={(d) => d.kind === 'restock' && setOrders((o) => [...o, d])} sentToStore={(n) => { if (n) { setSent(n); sendOrder() } }} />}
          {tab === 'center' && (seller ? <POS order={order} claim={() => setOrder((o) => (o ? { ...o, status: 'Na-scan' } : o))} openInv={() => setTab('inventory')} items={items} sell={(c) => setItems((it) => it.map((i) => ({ ...i, stock: i.stock - (c[i.id] || 0) })))} /> : <Profile role={role} order={order} verify={verify} />)}
          {tab === 'right' && (seller ? <Summary items={items} storeType={storeType} goAgent={() => setTab('agent')} orders={orders} receive={(l) => setItems((it) => it.map((i) => (i.id === l.id ? { ...i, stock: i.stock + l.qty * i.pack } : i)))} /> : <Inbox order={order} />)}
          {tab === 'inventory' && <Inventory items={items} setItems={setItems} back={() => setTab('center')} />}
          {tab === 'settings' && <Settings verify={verify} setVerify={setVerify} openInv={() => setTab('inventory')} role={role} dark={dark} setDark={setDark} large={large} setLarge={setLarge} storeType={storeType} setStoreType={setStoreType} modelReady={modelReady} setModelReady={setModelReady} limit={limit} setLimit={setLimit} logs={logs} />}
        </main>
        <nav className="grid grid-cols-3 gap-2 p-2 bg-card border-t border-black/5">
          {nav.map((n) => (
            <button key={n.id} onClick={() => setTab(n.id)} className={`min-h-16 rounded-2xl flex flex-col items-center justify-center gap-0.5 font-bold text-xs ${tab === n.id ? 'bg-brand text-white' : 'hover:bg-brand-soft'}`}>
              <n.icon className={`size-6 ${tab === n.id ? 'icon-pop' : ''}`} />{n.label}
            </button>))}
        </nav>
      </>}
      </div>
    </div>
  )
}
