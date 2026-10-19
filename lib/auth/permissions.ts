export const roles = ["owner", "admin", "hr", "manager", "employee", "auditor"] as const;
export type AppRole = (typeof roles)[number];

export function isAppRole(value: string | null | undefined): value is AppRole {
  return Boolean(value && roles.includes(value as AppRole));
}

export function canAccessAdmin(role: AppRole | null | undefined) {
  return role === "owner" || role === "admin" || role === "hr" || role === "auditor";
}

export function canManageAttendance(role: AppRole | null | undefined) {
  return role === "owner" || role === "admin" || role === "hr" || role === "manager";
}

export function roleLabel(role: AppRole | null | undefined) {
  const labels: Record<AppRole, string> = {
    owner: "Proprietário",
    admin: "Administrador",
    hr: "RH",
    manager: "Gestor",
    employee: "Colaborador",
    auditor: "Auditor",
  };
  return role ? labels[role] : "Acesso não configurado";
}
