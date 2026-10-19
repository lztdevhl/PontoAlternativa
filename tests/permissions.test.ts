import { describe, expect, it } from "vitest";
import { canAccessAdmin, canManageAttendance, isAppRole, roleLabel } from "@/lib/auth/permissions";

describe("authorization rules", () => {
  it("accepts only roles from the application allowlist", () => {
    expect(isAppRole("hr")).toBe(true);
    expect(isAppRole("root")).toBe(false);
    expect(isAppRole(null)).toBe(false);
  });

  it("separates administrative access from attendance management", () => {
    expect(canAccessAdmin("auditor")).toBe(true);
    expect(canManageAttendance("auditor")).toBe(false);
    expect(canManageAttendance("manager")).toBe(true);
    expect(canAccessAdmin("employee")).toBe(false);
  });

  it("has human-readable role labels", () => {
    expect(roleLabel("hr")).toBe("RH");
    expect(roleLabel(null)).toBe("Acesso não configurado");
  });
});
