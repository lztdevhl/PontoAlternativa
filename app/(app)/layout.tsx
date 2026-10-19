import { AppShell } from "@/components/app-shell";
import { getCurrentRole, requireUser } from "@/lib/auth/current-user";

export const dynamic = "force-dynamic";

export default async function AppLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const user = await requireUser();
  const role = await getCurrentRole(user.id);
  return <AppShell email={user.email} role={role}>{children}</AppShell>;
}
