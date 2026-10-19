import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./lib/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: "#101828",
        muted: "#667085",
        line: "#eaecf0",
        canvas: "#f8fafc",
        brand: {
          50: "#f0fdf9",
          100: "#ccfbea",
          500: "#16b364",
          600: "#079455",
          700: "#067647",
        },
      },
      boxShadow: {
        soft: "0 8px 32px rgba(16, 24, 40, 0.06)",
      },
    },
  },
  plugins: [],
};

export default config;
