// import { test, expect } from '@playwright/test';

// test('test', async ({ page }) => {
//   await page.locator('#SC span').nth(1).click();
//   await page.locator('#basic-settings div').filter({ hasText: 'Exam Tools Scientific' }).locator('span').nth(3).click();
//   await page.locator('#basic-settings div').filter({ hasText: 'Email & Communication Send' }).locator('span').nth(1).click();
//   await page.locator('div:nth-child(2) > .aesthetic-accordion-header').click();
//   await page.locator('#WR span').nth(1).click();
//   await page1.locator('.setting-card.proctoring-card.master-toggle > .toggle-switch > .slider').click();
  
  
//   import { test, expect } from '@playwright/test';

// test('exam automation until duration expires', async ({ page }) => {
//   test.slow();
  
//   await page.goto('https://digiscreener-staging.gcp.digivalitsolutions.com/fullscreenexam/app-landing/');
//   await page.getByRole('textbox', { name: 'Email ID' }).fill('rani@digivalsolutions.com');
//   await page.getByRole('button', { name: 'Verify' }).click();
//   await page.locator('//button[@class="register-now-btn"]').click();
//   await page.waitForTimeout(3000);
//   await page.getByRole('textbox', { name: 'Enter your first name' }).fill('student 1');
//   await page.getByRole('textbox', { name: 'Enter your last name' }).fill('D');
//   await page.locator('//button[@class="camera-btn"]').click();
//   await page.waitForTimeout(5000);
//   await page.locator('//button[@class="capture-btn"]').click();
//   await page.waitForTimeout(3000);
//   await page.locator('//button[@class="browse-btn"]').click();  


  

//   await page.locator('//button[@class="startexam-btn login_exam_card_save_button "]').click();
//   await page.locator('#national-id').fill('123');
//   await page.getByRole('button', { name: 'Login and Start Exam' }).click();
//   await page.getByRole('button', { name: 'Acknowledge and Start Exam' }).click();
// });


import { test, expect } from '@playwright/test';
import { examTakerConfig } from './pages/utlize.js';
import { questionsAndAnswers } from './pages/answer.js';

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
  waitTime: 400,
  enableLogging: true
};

// Helper function to normalize text for comparison
function normalizeText(text) {
  return text.trim().toLowerCase().replace(/\s+/g, ' ');
}

// Helper function to find MCQ answer by question text
function findMCQAnswer(questionText) {
  const normalized = normalizeText(questionText);
  
  // Try exact match first
  let match = questionsAndAnswers.mcq.find(qa => 
    normalizeText(qa.questionText) === normalized
  );
  
  // Try partial match
  if (!match) {
    match = questionsAndAnswers.mcq.find(qa => 
      normalized.includes(normalizeText(qa.questionText)) ||
      normalizeText(qa.questionText).includes(normalized)
    );
  }
  
  return match ? match.correctAnswer : questionsAndAnswers.fallbackMCQ;
}

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

// Function to answer exam questions with smart answer selection
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

      // Get question text for answer lookup
      const questionTextElement = page.locator(`#question-${i}`).locator('.question-text, .question-content, p').first();
      let questionText = '';
      try {
        questionText = await questionTextElement.textContent({ timeout: 3000 });
      } catch (e) {
        console.log(`  → Could not extract question text for Q${i + 1}`);
      }

      const hasOptions = await page.locator(`#question-${i}`).locator('text=/^[A-D]$/').count() > 0;

      if (hasOptions) {
        // MCQ Question
        await viewAttachments(page, i);
        
        // Find the correct answer from answer.js
        const correctAnswer = findMCQAnswer(questionText);
        console.log(`Q${i + 1} MCQ: ${correctAnswer} (${questionText.substring(0, 50)}...)`);

        const optionButton = page.locator(`#question-${i}`).getByText(correctAnswer, { exact: true });
        await optionButton.waitFor({ state: 'visible', timeout: 5000 });
        await optionButton.click();
      } else {
        // SAQ Question
        const answer = questionsAndAnswers.saq[Math.floor(Math.random() * questionsAndAnswers.saq.length)];
        console.log(`Q${i + 1} SAQ: ${answer.substring(0, 50)}...`);

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
    console.log('Answering questions...');
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
    console.error(`\n Error for ${student.name}:`, error.message, '\n');
    return false;
  }
}

// Main test - runs students based on configuration in students.js
test('Multiple students exam', async ({ page, context }) => {
  test.slow();
  
  // Get students from configuration file
  const studentsToRun = examTakerConfig.getStudents();
  
  console.log(`\n Total students to run: ${studentsToRun.length}\n`);
  
  test.setTimeout(studentsToRun.length * 300000); // 5 min per student

  const results = [];

  for (const student of studentsToRun) {
    const success = await runStudentExam(page, context, student, EXAM_CONFIG);
    results.push({ student: student.name, success });

    // Wait between students
    await page.waitForTimeout(3000);
  }

  // Print summary
  console.log('\n' + '='.repeat(60));
  console.log('EXAM COMPLETION SUMMARY');
  console.log('='.repeat(60));
  results.forEach(r => {
    console.log(`${r.success ? '✅' : '❌'} ${r.student}`);
  });
  console.log('='.repeat(60) + '\n');
});
