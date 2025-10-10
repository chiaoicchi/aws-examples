import type { Linter } from "eslint";
import configs, { globalIgnores } from "eslint/config";

import globals from "globals";

import tseslint from "typescript-eslint";
import eslintConfigPrettier from "eslint-config-prettier";

const config = configs.defineConfig([
  // TypeScript
  ...(tseslint.configs.recommended as Linter.Config[]),
  {
    languageOptions: {
      parser: tseslint.parser as Linter.Parser,
      sourceType: "module",
      globals: {
        ...globals.browser,
      },
    },
    plugins: {
      "@typescript-eslint": tseslint.plugin as unknown as Linter,
    },
  },

  // Prettier
  eslintConfigPrettier,

  // General
  globalIgnores(["**/dist/**/*", "**/node_modules/**/*"]),
]);

export default config;
