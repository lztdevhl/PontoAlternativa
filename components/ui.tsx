export function Card({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  return <section className={`rounded-2xl border border-line bg-white p-5 shadow-soft ${className}`}>{children}</section>;
}

export function StatusPill({ children, tone = "green" }: { children: React.ReactNode; tone?: "green" | "gray" | "amber" }) {
  const tones = { green: "bg-brand-50 text-brand-700", gray: "bg-slate-100 text-slate-600", amber: "bg-amber-50 text-amber-700" };
  return <span className={`inline-flex rounded-full px-2.5 py-1 text-[11px] font-semibold ${tones[tone]}`}>{children}</span>;
}
