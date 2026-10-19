import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Alternativa Ponto",
  description: "Gestão de jornada com registros confiáveis e tratamento auditável.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}
