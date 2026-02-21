/**
 * eslint.config.mjs - ESLint flat config (v10+)
 *
 * Defines code quality rules for the TypeScript backend.
 * Uses the new "flat config" format required since ESLint v9.
 */

import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import eslintConfigPrettier from 'eslint-config-prettier';

export default tseslint.config(
  // Start with recommended rules from ESLint and TypeScript-ESLint
  eslint.configs.recommended,
  ...tseslint.configs.recommended,

  // Prettier must be last - it turns off rules that conflict with formatting
  eslintConfigPrettier,

  // Our custom rules
  {
    rules: {
      // Warn about unused variables, but allow _prefixed ones (convention for intentionally unused)
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],

      // Warn about "any" type - we want to use proper types, but don't block on it
      '@typescript-eslint/no-explicit-any': 'warn',

      // Allow console.info, console.warn, console.error but warn on console.log
      'no-console': ['warn', { allow: ['warn', 'error', 'info'] }],
    },
  },

  // Ignore build output and config files
  {
    ignores: ['dist/', 'node_modules/', 'jest.config.ts'],
  }
);
