import Link from "next/link";
import { signOut } from "@/app/actions/auth";
import { canAccessAdmin, roleLabel, type AppRole } from "@/lib/auth/permissions";

const links = [
  { href: "/dashboard", label: "Visão geral", mark: "01" },
  { href: "/ponto", label: "Meu ponto", mark: "02" },
  { href: "/historico", label: "Histórico", mark: "03" },
  { href: "/solicitacoes", label: "Solicitações", mark: "04" },
  { href: "/perfil", label: "Perfil", mark: "05" },
];

const adminLinks = [
  { href: "/rh", label: "Painel do RH", mark: "RH" },
  { href: "/rh/funcionarios", label: "Funcionários", mark: "06" },
];

export function AppShell({ children, email, role }: { children: React.ReactNode; email?: string; role?: AppRole | null }) {
  return (
    <div className="min-h-screen bg-canvas lg:flex">
      <aside className="border-b border-line bg-white lg:fixed lg:inset-y-0 lg:flex lg:w-[254px] lg:flex-col lg:border-b-0 lg:border-r">
        <div className="flex items-center gap-3 px-5 py-5 lg:px-7 lg:py-7">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-ink text-xs font-bold text-white">AP</div>
          <div><p className="text-sm font-semibold tracking-tight text-ink">Alternativa Ponto</p><p className="text-[11px] text-muted">Workspace interno</p></div>
        </div>
        <nav className="flex gap-1 overflow-x-auto px-3 pb-3 lg:block lg:px-4 lg:py-3">
          <p className="hidden px-3 pb-3 text-[10px] font-semibold uppercase tracking-[0.18em] text-slate-400 lg:block">Navegação</p>
          {links.map((link) => <Link key={link.href} href={link.href} className="group flex shrink-0 items-center gap-3 rounded-xl px-3 py-2.5 text-sm text-muted transition hover:bg-slate-50 hover:text-ink"><span className="font-mono text-[10px] text-slate-300 group-hover:text-brand-600">{link.mark}</span>{link.label}</Link>)}
          {canAccessAdmin(role) ? <><p className="hidden px-3 pb-2 pt-6 text-[10px] font-semibold uppercase tracking-[0.18em] text-slate-400 lg:block">Administração</p>{adminLinks.map((link) => <Link key={link.href} href={link.href} className="group flex shrink-0 items-center gap-3 rounded-xl px-3 py-2.5 text-sm text-muted transition hover:bg-slate-50 hover:text-ink"><span className="font-mono text-[10px] text-slate-300 group-hover:text-brand-600">{link.mark}</span>{link.label}</Link>)}</> : null}
        </nav>
        <div className="hidden lg:mt-auto lg:block lg:p-5">
          <div className="rounded-2xl bg-slate-50 p-4"><p className="text-[10px] font-semibold uppercase tracking-[0.16em] text-slate-400">Sessão atual</p><p className="mt-2 truncate text-xs font-medium text-ink">{email ?? "usuário autenticado"}</p><p className="mt-1 text-xs text-muted">{roleLabel(role)}</p></div>
          <form action={signOut}><button className="mt-4 w-full rounded-xl px-3 py-2 text-left text-xs font-medium text-muted transition hover:bg-red-50 hover:text-red-700">Sair da conta</button></form>
        </div>
      </aside>
      <main className="min-w-0 flex-1 lg:ml-[254px]">{children}</main>
    </div>
  );
}
