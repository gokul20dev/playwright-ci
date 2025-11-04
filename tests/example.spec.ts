import { tests, expect } from '@playwright/test';

test('Homepage has title', async ({ page }) => {
  await page.goto('https://playwright.dev/');
  await expect(page).toHaveTitle(/Playwright/);
});

test('Docs link works', async ({ page }) => {
  await page.goto('https://playwright.dev/');
  await page.click('text=Docs');
  await expect(page).toHaveURL(/.*docs/);
});

