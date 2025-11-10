// import { test, expect } from '@playwright/test';
// import { Loginpage } from './pages/Loginpage.js';
// import { examMakerConfig } from './pages/utlize.js';

// test('test', async ({ page }) => {
//   test.slow();
  
//   const loginpage = new Loginpage(page, examMakerConfig.baseUrl);
//   await loginpage.login(examMakerConfig.orgId, examMakerConfig.email, examMakerConfig.password);
  
//   const examMakerPage = await loginpage.navigateToExamMaker();
//   const workingPage = examMakerPage;
  
//   // Set default timeout for the page
//   workingPage.setDefaultTimeout(15000);
  
//   // Navigate to Completed tab
//   await workingPage.getByRole('button', { name: 'Today' }).click();
//   await workingPage.locator('(//div[@data-number="2"])[1]').click();
//   await workingPage.locator('.action-dropdown.drop-down.active .report-btn.act-pointer').click();
//   await workingPage.waitForTimeout(4000);
  
//   // Generate report
//   await workingPage.locator('//button[@class="generate-report-btn"]').click();
  
//   // Wait for loading to complete
//   await workingPage.locator('.unified-loader-container').waitFor({ state: 'hidden', timeout: 30000 });

//   // Navigate through tabs
//   await workingPage.locator('(//span[@class="tab-text"])[2]').click();
//   await workingPage.waitForTimeout(4000);

//   await workingPage.locator('(//span[@class="tab-text"])[3]').click();
//   await workingPage.waitForTimeout(4000);

// //   await workingPage.locator('(//button[@id="student-exam-details"])[1]').click();
// //   await workingPage.evaluate(() => {
// //   window.scrollTo(0, document.body.scrollHeight);
// // });
//   await workingPage.waitForTimeout(1000); // Wait for smooth scroll to finish

  
//   await workingPage.locator('#publish-tab').click();
//   await workingPage.waitForLoadState('domcontentloaded');
  
//   // Select report type
//   await workingPage.locator('#report-type-btn').click();
  
//   const detailedRadio = workingPage.locator('input[value="detailed"]');
//   await detailedRadio.waitFor({ state: 'visible' });
//   await detailedRadio.click();
//   await workingPage.waitForTimeout(500);
  
//   // Publish report
//   await workingPage.locator('#publish-report').click();
//   await workingPage.waitForTimeout(500);
  
//   // Confirm publish
//   await workingPage.locator('button.confirm-btn').click();
  
//   // // Wait for success message
//   const publishSuccessMsg = workingPage.getByText(/published successfully/i);
//   await publishSuccessMsg.waitFor({ state: 'visible' });
//   await publishSuccessMsg.waitFor({ state: 'hidden', timeout: 10000 });

//   await workingPage.locator('//div[@class="ag-labeled ag-label-align-right ag-checkbox ag-input-field ag-header-select-all"]').click();
//     await workingPage.waitForTimeout(500);
//   // Send email
//   await workingPage.locator('#send-email-button').click();
//   await workingPage.waitForTimeout(500);
  
//   // Confirm send
//   await workingPage.locator('button.confirm-btn').click();
  
//   // Wait for email success message
//   const emailSuccessMsg = workingPage.getByText(/successfully sent email notifications/i);
//   await emailSuccessMsg.waitFor({ state: 'hidden', timeout: 10000 });
  
//   // Refresh data
//   await workingPage.locator('#refresh-data').click();
  
//   // Wait for refresh to complete - better than fixed timeout
//   await workingPage.waitForLoadState('networkidle');
//   await workingPage.waitForTimeout(2000); // Small buffer for final updates
// });



import { test, expect } from '@playwright/test';
import { Loginpage } from './pages/Loginpage.js';
import { ExamMaker } from './pages/ExamMaker.js';
import { examMakerConfig } from './pages/utlize.js';
import fs from 'fs';
import path from 'path';

test('test', async ({ page }) => {
  test.slow();

    // Check if exam info file exists
    const examInfoPath = path.join('./test-data', 'exam-info.json');
    if (!fs.existsSync(examInfoPath)) {
      throw new Error('Exam info file not found! Please run the exam maker test first.');
    }
  
  // Read only the exam name
  const examInfo = JSON.parse(fs.readFileSync(examInfoPath, 'utf-8'));
  const examName = examInfo.examName;
  console.log('Testing reports for exam:', examName);

  
  const loginpage = new Loginpage(page, examMakerConfig.baseUrl);
  await loginpage.login(examMakerConfig.orgId, examMakerConfig.email, examMakerConfig.password);
  
  const examMakerPage = await loginpage.navigateToExamMaker();
  const workingPage = examMakerPage;
  workingPage.setDefaultTimeout(15000);
  
  // Navigate to reports
  await workingPage.getByRole('button', { name: 'Today' }).click();
  await workingPage.waitForTimeout(2000);
  
  // Find the exam row by name
  const examRow = workingPage.locator('div.ag-row').filter({ 
    hasText: examName 
  }).first();
  
  console.log('Looking for exam in reports:', examName);
  await examRow.waitFor({ state: 'visible', timeout: 10000 });
  
  // Click the action menu for the created exam
  await examRow.locator('i.bx.bx-dots-vertical-rounded.action-menu-main').first().click();
  await workingPage.waitForTimeout(500);
  
  // Click report button
  await workingPage.locator('.action-dropdown.drop-down.active .report-btn.act-pointer').click();
  await workingPage.waitForTimeout(4000);
  
  // Generate report
  await workingPage.locator('//button[@class="generate-report-btn"]').click();
  
  // Wait for loading to complete
  await workingPage.locator('.unified-loader-container').waitFor({ state: 'hidden', timeout: 30000 });

  // Navigate through tabs
  await workingPage.locator('(//span[@class="tab-text"])[2]').click();
  await workingPage.waitForTimeout(4000);

  await workingPage.locator('(//span[@class="tab-text"])[3]').click();
  await workingPage.waitForTimeout(4000);

  await workingPage.waitForTimeout(1000);
  
  await workingPage.locator('#publish-tab').click();
  await workingPage.waitForLoadState('domcontentloaded');
  
  // Select report type
  await workingPage.locator('#report-type-btn').click();
  
  const detailedRadio = workingPage.locator('input[value="detailed"]');
  await detailedRadio.waitFor({ state: 'visible' });
  await detailedRadio.click();
  await workingPage.waitForTimeout(500);
  
  // Publish report
  await workingPage.locator('#publish-report').click();
  await workingPage.waitForTimeout(500);
  
  // Confirm publish
  await workingPage.locator('button.confirm-btn').click();
  
  // Wait for success message
  const publishSuccessMsg = workingPage.getByText(/published successfully/i);
  await publishSuccessMsg.waitFor({ state: 'visible' });
  await publishSuccessMsg.waitFor({ state: 'hidden', timeout: 10000 });

  await workingPage.locator('//div[@class="ag-labeled ag-label-align-right ag-checkbox ag-input-field ag-header-select-all"]').click();
  await workingPage.waitForTimeout(500);
  
  // Send email
  await workingPage.locator('#send-email-button').click();
  await workingPage.waitForTimeout(500);
  
  // Confirm send
  await workingPage.locator('button.confirm-btn').click();
  
  // Wait for email success message
  const emailSuccessMsg = workingPage.getByText(/successfully sent email notifications/i);
  await emailSuccessMsg.waitFor({ state: 'hidden', timeout: 10000 });
  
  // Refresh data
  await workingPage.locator('#refresh-data').click();
  
  // Wait for refresh to complete
  await workingPage.waitForLoadState('networkidle');
  await workingPage.waitForTimeout(2000);
  
  console.log('Report test completed for exam:', examName);
});