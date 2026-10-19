import { Card, StatusPill } from "@/components/ui";

const metrics = [
  { label: "Jornada de hoje", value: "00h 00min", note: "Nenhuma marcação registrada", accent: "bg-slate-100" },
  { label: "Banco de horas", value: "+02h 40min", note: "Período atual", accent: "bg-brand-100" },
  { label: "Solicitações abertas", value: "02", note: "Aguardando análise do RH", accent: "bg-amber-100" },
];

export default function DashboardPage() {
  return <div className="mx-auto max-w-[1400px] px-5 py-6 sm:px-8 lg:px-10 lg:py-10">
    <header className="mb-8 flex flex-col justify-between gap-5 sm:flex-row sm:items-end"><div><p className="mb-2 text-xs font-semibold uppercase tracking-[0.18em] text-brand-700">Sexta-feira, 18 de outubro de 2026</p><h1 className="text-3xl font-semibold tracking-[-0.04em] text-ink sm:text-4xl">Bom dia, colaborador.</h1><p className="mt-2 text-sm text-muted">Aqui está um resumo do seu espaço de trabalho.</p></div><StatusPill>Ambiente de testes</StatusPill></header>
    <div className="grid gap-4 md:grid-cols-3">{metrics.map((metric) => <Card key={metric.label} className="relative overflow-hidden"><div className={`absolute right-5 top-5 h-3 w-3 rounded-full ${metric.accent}`} /><p className="text-sm text-muted">{metric.label}</p><p className="mt-5 text-3xl font-semibold tracking-[-0.05em] text-ink">{metric.value}</p><p className="mt-2 text-xs text-muted">{metric.note}</p></Card>)}</div>
    <div className="mt-4 grid gap-4 lg:grid-cols-[1.4fr_1fr]">
      <Card><div className="flex items-start justify-between"><div><p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Ação principal</p><h2 className="mt-2 text-xl font-semibold tracking-tight text-ink">Registre sua jornada</h2><p className="mt-1 max-w-md text-sm leading-6 text-muted">As marcações originais são preservadas e recebem o horário confiável do servidor.</p></div><div className="hidden h-12 w-12 items-center justify-center rounded-2xl bg-brand-50 text-brand-700 sm:flex">↗</div></div><div className="mt-7 flex flex-wrap gap-3"><a href="/ponto" className="rounded-xl bg-ink px-4 py-3 text-sm font-semibold text-white transition hover:bg-slate-700">Abrir meu ponto</a><a href="/historico" className="rounded-xl border border-line px-4 py-3 text-sm font-semibold text-ink transition hover:bg-slate-50">Ver histórico</a></div></Card>
      <Card><p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Próximos passos</p><div className="mt-5 space-y-4"><div className="flex gap-3"><span className="mt-1 h-2 w-2 rounded-full bg-brand-500" /><div><p className="text-sm font-medium text-ink">Complete seu perfil</p><p className="mt-1 text-xs text-muted">Mantenha seus dados atualizados.</p></div></div><div className="flex gap-3"><span className="mt-1 h-2 w-2 rounded-full bg-slate-300" /><div><p className="text-sm font-medium text-ink">Conheça seus comprovantes</p><p className="mt-1 text-xs text-muted">Documentos ficam disponíveis após as marcações.</p></div></div></div></Card>
    </div>
  </div>;
}
