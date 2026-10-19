import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Alternativa Ponto",
    short_name: "Ponto",
    description: "Registro de jornada e acompanhamento de ponto.",
    start_url: "/dashboard",
    display: "standalone",
    background_color: "#f8fafc",
    theme_color: "#101828",
    lang: "pt-BR",
    icons: [],
  };
}
