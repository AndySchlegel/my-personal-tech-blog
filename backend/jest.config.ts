/**
 * jest.config.ts - Test configuration
 *
 * Tells Jest how to handle TypeScript files.
 * Uses ts-jest to compile .ts files before running tests.
 */

export default {
  // Use ts-jest so we can write tests in TypeScript
  preset: 'ts-jest',

  // Run tests in a Node.js environment (not browser)
  testEnvironment: 'node',

  // Where to find test files: anything in tests/ ending with .test.ts
  testMatch: ['<rootDir>/tests/**/*.test.ts'],

  // Don't look for tests in these folders
  testPathIgnorePatterns: ['/node_modules/', '/dist/'],
};
