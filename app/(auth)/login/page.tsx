import { signIn } from "@/app/actions/auth";

type LoginPageProps = { searchParams: Promise<{ error?: string }> };

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const { error } = await searchParams;

  return (
    <main className="grid-noise flex min-h-screen items-center justify-center px-5 py-10">
      <div className="w-full max-w-[440px]">
        <div className="mb-8 flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-ink text-sm font-bold text-white shadow-soft">AP</div>
          <div>
            <p className="text-sm font-semibold tracking-tight text-ink">Alternativa Ponto</p>
            <p className="text-xs text-muted">Jornada clara. Registro confiável.</p>
          </div>
        </div>
        <section className="rounded-3xl border border-line bg-white p-7 shadow-soft sm:p-9">
          <div className="mb-8">
            <p className="mb-3 text-xs font-semibold uppercase tracking-[0.18em] text-brand-700">Acesso seguro</p>
            <h1 className="text-3xl font-semibold tracking-[-0.04em] text-ink">Entre na sua conta</h1>
            <p className="mt-2 text-sm leading-6 text-muted">Use suas credenciais individuais para acessar o painel.</p>
          </div>
          {error ? <p className="mb-5 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</p> : null}
          <form action={signIn} className="space-y-5">
            <label className="block text-sm font-medium text-ink">
              E-mail
              <input name="email" type="email" autoComplete="email" required placeholder="voce@empresa.com.br" className="mt-2 block w-full rounded-xl border border-line bg-white px-4 py-3 text-sm outline-none transition placeholder:text-slate-400 focus:border-brand-500 focus:ring-4 focus:ring-brand-100" />
            </label>
            <label className="block text-sm font-medium text-ink">
              Senha
              <input name="password" type="password" autoComplete="current-password" required placeholder="••••••••" className="mt-2 block w-full rounded-xl border border-line bg-white px-4 py-3 text-sm outline-none transition placeholder:text-slate-400 focus:border-brand-500 focus:ring-4 focus:ring-brand-100" />
            </label>
            <button type="submit" className="w-full rounded-xl bg-ink px-4 py-3.5 text-sm font-semibold text-white transition hover:bg-slate-700 focus:outline-none focus:ring-4 focus:ring-slate-200">Entrar no painel</button>
          </form>
          <p className="mt-7 border-t border-line pt-5 text-xs leading-5 text-muted">O acesso é individual. Em produção, a autenticação administrativa deverá exigir MFA.</p>
        </section>
        <p className="mt-6 text-center text-xs text-muted">Ambiente inicial · Fase 1</p>
      </div>
    </main>
  );
}
