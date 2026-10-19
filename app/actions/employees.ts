"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireRole } from "@/lib/auth/current-user";
import { createClient } from "@/lib/supabase/server";

function optionalUuid(value: FormDataEntryValue | null) {
  const normalized = String(value ?? "").trim();
  return normalized || null;
}

export async function createEmployee(formData: FormData) {
  await requireRole(["owner", "admin", "hr"]);

  const supabase = await createClient();
  const { error } = await supabase.rpc("create_employee_with_assignment", {
    p_establishment_id: String(formData.get("establishment_id") ?? ""),
    p_department_id: optionalUuid(formData.get("department_id")),
    p_manager_employee_id: optionalUuid(formData.get("manager_employee_id")),
    p_work_schedule_id: optionalUuid(formData.get("work_schedule_id")),
    p_user_id: optionalUuid(formData.get("user_id")),
    p_registration_code: String(formData.get("registration_code") ?? ""),
    p_full_name: String(formData.get("full_name") ?? ""),
    p_email: String(formData.get("email") ?? ""),
    p_job_title: String(formData.get("job_title") ?? ""),
    p_starts_on: String(formData.get("starts_on") ?? ""),
  });

  if (error) {
    const message = error.code === "42501"
      ? "Sua conta não tem permissão para este cadastro."
      : "Verifique os dados e o escopo do estabelecimento.";
    redirect(`/rh/funcionarios?error=${encodeURIComponent(message)}`);
  }

  revalidatePath("/rh/funcionarios");
  revalidatePath("/rh");
  redirect("/rh/funcionarios?success=Funcionário%20cadastrado");
}
