import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: 'tests',

  // ------------------------------
  // 📊 REPORTERS: HTML + JSON
  // ------------------------------
  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['json', { outputFile: 'results.json' }]
  ],

  // ------------------------------
  // ⚙️ DEFAULT SETTINGS
  // ------------------------------
  use: {
    headless: true,
    browserName: 'chromium',
    viewport: { width: 1280, height: 720 },
  },
});

