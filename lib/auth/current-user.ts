import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { isAppRole, type AppRole } from "@/lib/auth/permissions";

export async function getCurrentUser() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

export async function requireUser() {
  const user = await getCurrentUser();
  if (!user) redirect("/login");
  return user;
}

export async function getCurrentRole(userId: string): Promise<AppRole | null> {
  const roles = await getCurrentRoles(userId);
  const priority: AppRole[] = ["owner", "admin", "hr", "manager", "auditor", "employee"];
  return priority.find((candidate) => roles.includes(candidate)) ?? null;
}

export async function getCurrentRoles(userId: string): Promise<AppRole[]> {
  const supabase = await createClient();
  const { data } = await supabase.from("user_roles").select("role").eq("user_id", userId);
  return Array.from(new Set((data ?? []).map((item) => item.role).filter(isAppRole)));
}

export async function requireRole(allowedRoles: AppRole[]) {
  const user = await requireUser();
  const roles = await getCurrentRoles(user.id);
  const role = roles.find((candidate) => allowedRoles.includes(candidate)) ?? null;
  if (!role || !allowedRoles.includes(role)) redirect("/dashboard");
  return { user, role };
}
