import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: 'tests',
  reporter: [['html', { outputFolder: 'playwright-report', open: 'never' }]],
  use: {
    headless: true,
    browserName: 'chromium',
    viewport: { width: 1280, height: 720 },
  },
});

