import js from "@eslint/js";
import globals from "globals";
import tseslint from "typescript-eslint";
import { defineConfig } from "eslint/config";

export default defineConfig([
  // Base JS/TS rules for a Node.js project
  {
    files: ["**/*.{js,mjs,cjs,ts,mts,cts}"],
    plugins: { js },
    extends: ["js/recommended"],
    languageOptions: {
      globals: globals.node,
    },
    ignores: ["lib/**", ".eslintrc.js"],
  },
  // TypeScript recommended config
  tseslint.configs.recommended,
]);
