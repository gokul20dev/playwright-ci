import { test, expect } from '@playwright/test';
import { examTakerConfig } from './pages/utlize.js';

test.use({
  headless: false,
  permissions: ['camera'],
  launchOptions: {
    args: [
      '--start-maximized',
      '--use-fake-ui-for-media-stream',
      '--auto-select-desktop-capture-source=Built-in display',
      '--auto-select-desktop-capture-source=Entire screen'
    ]
  }
});

const EXAM_CONFIG = {
  totalQuestions: 50,
  answerOptions: ['A', 'B', 'C'],
  saqAnswers: [
    'This is a sample answer.Need to understand the complexity of the unknown error that have been the access to the more reliable in this containment',
    'The solution is correct during the localhost are making the continuous fallback the localhost.Basically that we punishing the continue maintaining sources',
    'Based on the analysis we are required the basic knowledge from the output source.this will be made due to the electro containment functioning them'
  ],
  waitTime: 400,
  enableLogging: true
};

// Function to view attachments
async function viewAttachments(page, questionIndex) {
  try {
    const attachments = page.locator(`#question-${questionIndex} span.open-choice-attachment-text`);
    const count = await attachments.count();

    if (count > 0) {
      console.log(`  → Found ${count} attachment(s)`);
      for (let i = 0; i < count; i++) {
        await attachments.nth(i).click();
        await page.waitForLoadState('networkidle', { timeout: 5000 }).catch(() => {});
        await page.waitForTimeout(5000);
        console.log(`  → Displayed attachment ${i + 1}/${count} for 5 seconds`);

        const closeBtn = page.locator('button:has-text("Close")').first();
        if (await closeBtn.isVisible({ timeout: 4000 }).catch(() => false)) {
          await closeBtn.click();
          await page.waitForLoadState('domcontentloaded').catch(() => {});
        }
      }
    }
  } catch (error) {
    console.log(`  → Attachment error: ${error.message}`);
  }
}

// Function to answer exam questions
async function answerExam(page, config) {
  await page.waitForSelector('#question-0', { timeout: 10000 });

  for (let i = 0; i < config.totalQuestions; i++) {
    try {
      if (page.isClosed()) {
        console.log(`Page closed at Q${i + 1} - stopping test`);
        return false;
      }

      const questionExists = await page.locator(`#question-${i}`).count();
      if (questionExists === 0) {
        console.log(`Q${i + 1} not found - exam may have ended`);
        break;
      }

      await page.waitForSelector(`#question-${i}`, { timeout: 15000, state: 'visible' });

      const hasOptions = await page.locator(`#question-${i}`).locator('text=/^[A-D]$/').count() > 0;

      if (hasOptions) {
        await viewAttachments(page, i);
        const answer = config.answerOptions[Math.floor(Math.random() * config.answerOptions.length)];
        console.log(`Q${i + 1} MCQ: ${answer}`);

        const optionButton = page.locator(`#question-${i}`).getByText(answer, { exact: true });
        await optionButton.waitFor({ state: 'visible', timeout: 5000 });
        await optionButton.click();
      } else {
        const answer = config.saqAnswers[Math.floor(Math.random() * config.saqAnswers.length)];
        console.log(`Q${i + 1} SAQ`);

        const textbox = page.locator(`#question-${i}`).getByRole('textbox');
        await textbox.waitFor({ state: 'visible', timeout: 5000 });
        await textbox.fill(answer);
      }

      const nextButton = page.getByRole('button', { name: /Next/i });
      const isNextVisible = await nextButton.isVisible({ timeout: 3000 }).catch(() => false);

      if (isNextVisible) {
        await nextButton.click();
        if (i + 1 < config.totalQuestions) {
          await page.waitForSelector(`#question-${i + 1}`, {
            timeout: 10000,
            state: 'attached'
          }).catch(() => {
            console.log(`Next question Q${i + 2} didn't load - continuing anyway`);
          });
        }
      } else {
        console.log(`No Next button at Q${i + 1} - stopping`);
        break;
      }

    } catch (error) {
      console.error(`Error on Q${i + 1}:`, error.message);

      if (page.isClosed()) {
        console.log('Page closed - stopping test');
        return false;
      }

      const nextButton = page.getByRole('button', { name: /Next/i });
      const canContinue = await nextButton.isVisible({ timeout: 2000 }).catch(() => false);

      if (canContinue) {
        console.log(`Attempting to continue from Q${i + 1}...`);
        await nextButton.click().catch(() => {});
        continue;
      }

      break;
    }
  }

  return true;
}

// Function to submit exam
async function submitExam(page) {
  try {
    if (page.isClosed()) {
      console.log('Page already closed - cannot submit');
      return false;
    }

    const submitButton = page.getByRole('button', { name: /Submit/i }).first();
    if (await submitButton.isVisible({ timeout: 5000 }).catch(() => false)) {
      await submitButton.click();
      await page.getByLabel('Alert').getByRole('button', { name: 'Submit' }).click({ timeout: 10000 });
      await page.getByRole('dialog', { name: /Exam Completed Successfully/i }).waitFor({ state: 'visible', timeout: 10000 });
      console.log('✓ Exam submitted successfully!');
      return true;
    } else {
      console.log('Submit button not found - exam may have auto-completed');
      return false;
    }
  } catch (error) {
    console.error('Submit failed:', error.message);
    return false;
  }
}

// Function for one student to complete exam
async function runStudentExam(page, context, student, config) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(` Starting exam for: ${student.name} (${student.email})`);
  console.log(`${'='.repeat(60)}\n`);

  try {
    // Grant permissions
    await context.grantPermissions(['camera'], {
      origin: 'https://digiscreener-staging.gcp.digivalitsolutions.com'
    });

    // Navigate and login
    await page.goto('https://digiscreener-staging.gcp.digivalitsolutions.com/fullscreenexam/app-landing/index.html?cid=DIGI-002');
    await page.waitForTimeout(3000);
    await page.getByRole('textbox', { name: 'Email ID' }).click();
    await page.getByRole('textbox', { name: 'Email ID' }).fill(student.email);
    await page.getByRole('button', { name: 'Verify' }).click();

    // Select exam
    await page.locator('button.startexam-btn.login_exam_card_save_button')
      .nth(0)
      .click();

    // Enter national ID
    await page.locator('#national-id').click();
    await page.locator('#national-id').fill(student.nationalId);
    await page.getByRole('button', { name: 'Login and Start Exam' }).click();
    await page.getByRole('button', { name: 'Acknowledge and Start Exam' }).click();

    // Answer exam
    console.log(' Answering questions...');
    const answered = await answerExam(page, config);

    if (answered) {
      console.log(' Submitting exam...');
      const submitted = await submitExam(page);

      if (submitted) {
        console.log(`\n ${student.name} Exam Completed successfully!\n`);
        return true;
      }
    }

    console.log(`\n ${student.name} exam incomplete\n`);
    return false;

  } catch (error) {
    console.error(`\nError for ${student.name}:`, error.message, '\n');
    return false;
  }
}

// Main test - runs students based on configuration in students.js
test('Multiple students exam', async ({ page, context }) => {
  test.slow();
  
  // Get students from configuration file
  const studentsToRun = examTakerConfig.getStudents();
  
  console.log(`\nTotal students to run: ${studentsToRun.length}\n`);
  
  test.setTimeout(studentsToRun.length * 300000); // 5 min per student

  const results = [];

  for (const student of studentsToRun) {
    const success = await runStudentExam(page, context, student, EXAM_CONFIG);
    results.push({ student: student.name, success });

    // Wait between students
    await page.waitForTimeout(3000);
  }

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('EXAM COMPLETION SUMMARY');
  console.log('='.repeat(60));
  results.forEach(({ student, success }) => {
    console.log(`${success ? '' : ''} ${student}`);
  });
  console.log('='.repeat(60) + '\n');

});