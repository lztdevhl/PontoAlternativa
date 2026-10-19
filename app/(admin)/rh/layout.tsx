import { requireRole } from "@/lib/auth/current-user";

export const dynamic = "force-dynamic";

export default async function HrLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  await requireRole(["owner", "admin", "hr", "auditor"]);
  return children;
}
