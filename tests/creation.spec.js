import { test, expect } from '@playwright/test';
import { Loginpage } from './pages/Loginpage.js';
import { ExamMaker } from './pages/ExamMaker.js';
import { examMakerConfig } from './pages/utlize.js';
import path from 'path';
import os from 'os';
import fs from 'fs';

test('create new exam with dynamic values', async ({ page }) => {
  test.slow();
  
  // Login and setup
  const loginpage = new Loginpage(page, examMakerConfig.baseUrl);
  await loginpage.login(examMakerConfig.orgId, examMakerConfig.email, examMakerConfig.password);
  
  const examMakerPage = await loginpage.navigateToExamMaker();
  const examMaker = new ExamMaker(examMakerPage);
  
  // Create exam and store the generated name with timestamp
  const examName = await examMaker.createNewExam();
  const createdAt = new Date(); // Capture exact creation time

    // Calculate scheduled time (30 minutes in future)
    const scheduledTime = new Date(createdAt.getTime() + 30 * 60 * 1000);

  console.log('Created exam with name:', examName);
  console.log('Creation timestamp:', createdAt.toISOString());
  
  await examMakerPage.waitForTimeout(2000);
    
    // Import questions from Excel
    const questionsFile = path.join(os.homedir(), 'Downloads', 'question template.xlsx');
    if (!fs.existsSync(questionsFile)) {
      throw new Error(`Question file not found at: ${questionsFile}`);
    }
    
    await examMakerPage.click('button#import-questions-btn');
    await examMakerPage.waitForSelector('#dragDropZone', { state: 'visible' });
    
    const fileInput = examMakerPage.locator('//div[@id="dragDropZone"]//input[@type="file"]');
    await fileInput.setInputFiles(questionsFile);
    await examMakerPage.waitForTimeout(2000);
    
    await examMakerPage.getByRole('button', { name: 'Process Questions' }).click();
    await examMakerPage.waitForTimeout(3000);
    
    // Helper function to upload attachment
    async function uploadQuestionAttachment(questionNumber, attachmentId, fileName) {
      await examMakerPage.getByText(`Question${questionNumber} ▼ Map`).click();
      await examMakerPage.locator(`#${attachmentId} i`).click();
      
      const filePath = path.join(os.homedir(), 'Downloads', fileName);
      const fileInput = examMakerPage.locator('#attachmentPanel input[type="file"]').first();
      await fileInput.setInputFiles(filePath);
      
      await examMakerPage.locator('#attachmentPanel').getByRole('button', { name: 'Close' }).waitFor({ state: 'visible' });
      await examMakerPage.locator('#attachmentPanel').getByRole('button', { name: 'Close' }).click();
    }
    
    // Helper function to upload choice attachment
    async function uploadChoiceAttachment(questionNumber, choiceId, fileName) {
      await examMakerPage.getByText(`Question${questionNumber} ▼ Map`).click();
      await examMakerPage.locator(`#${choiceId} i`).first().click();
      
      const filePath = path.join(os.homedir(), 'Downloads', fileName);
      const fileInput = examMakerPage.locator(`//div[@class='choice-attachment-main-container']//input[@type='file']`);
      await fileInput.setInputFiles(filePath);
      
      await examMakerPage.locator('#choice-attachmentPanel').getByRole('button', { name: 'Close' }).waitFor({ state: 'visible' });
      await examMakerPage.locator('#choice-attachmentPanel').getByRole('button', { name: 'Close' }).click();
    }
    
    // Upload question attachments
    await uploadQuestionAttachment(2, 'attachment-container-2', 'image4.png');
    await uploadQuestionAttachment(5, 'attachment-container-5', 'images1.jpeg');
    await uploadQuestionAttachment(15, 'attachment-container-15', 'images2.jpeg');
    
    // Upload choice attachments
    await uploadChoiceAttachment(12, 'choice-attachment-container-12-B', 'img.png');
    await uploadChoiceAttachment(13, 'choice-attachment-container-13-B', 'images1.jpeg');
    
    // Navigate to next step
    await examMakerPage.getByRole('button', { name: 'Next' }).click();
    await examMakerPage.getByLabel('Preview Questions').getByRole('button', { name: 'Next' }).click();
  
    
    // Add students
    const students = [
      { email: 'student01@gmail.com', passcode: '123' },
      { email: 'student02@gmail.com', passcode: '123' },
    ];


    // const filePath2 = path.join(os.homedir(), 'Downloads', 'Attender template.xlsx');

    // if (!fs.existsSync(filePath2)) {
    //   throw new Error(`Attender template not found at: ${filePath2}`);
    // }
    

    // await examMakerPage.click('button#importButton');
    // await examMakerPage.waitForSelector('#attendeesDragDropZone', { state: 'visible' });

    // const fileInput2 = examMakerPage.locator('//div[@id="attendeesDragDropZone"]//input[@type="file"]');
    // await fileInput2.setInputFiles(filePath2);
    // await examMakerPage.waitForTimeout(3000);

    // await examMakerPage.getByRole('button', { name: 'Import Attendees' }).click();
    // await examMakerPage.waitForTimeout(3000);
    
    // // Wait for upload confirmation instead of fixed delay
    // await examMakerPage.waitForSelector('text=Successfully imported students', { timeout: 10000 });
    
    for (const student of students) {
      await examMakerPage.getByRole('textbox', { name: 'Enter Email Id' }).fill(student.email);
      await examMakerPage.getByRole('textbox', { name: 'Enter Pass Code' }).fill(student.passcode);
      await examMakerPage.getByRole('button', { name: 'Add' }).click();
      
      // Wait for success message with error handling
      try{
        await examMakerPage.waitForSelector('text=Successfully imported 30 attendees', { timeout: 10000 });
        } catch (e) {
          console.log(`Success message not visible, continuing...`);
        }
    }
  
    // Delete selected students (4 and 5)
// Using the unique IDs from the error message
// If rows are in consistent order, use nth 
  // await examMakerPage.getByLabel('Press Space to toggle row').nth(3).check();
  // await examMakerPage.getByLabel('Press Space to toggle row').nth(4).check();
  //   await examMakerPage.locator('#delete-selected').click();
  //   try {
  //     await examMakerPage.locator('//div[@class="custom-modal-container"]').waitFor({ state: 'visible', timeout: 4000 });
  //   } catch (e) {
  //     console.log('Delete modal check - continuing...');
  //   }
    
  //   await examMakerPage.getByRole('button', { name: 'Delete' }).click();
  //   await examMakerPage.waitForTimeout(1000);
  
    // Finalize and start exam
    await examMakerPage.getByRole('button', { name: 'Finalize' }).click();
    await examMakerPage.waitForTimeout(1000);
    
    // Wait for navigation to exam list
    try {
      await examMakerPage.getByRole('button', { name: 'Today' }).waitFor({ state: 'visible', timeout: 5000 });
    } catch (e) {
      console.log('Today button not found, continuing...');
    }
    
    // NEW CODE: Start the exam we just created using its name
    await examMaker.startCreatedExam();
    // ========================================
    
    console.log(`Successfully started exam: ${examName}`);
    
    // Wait for exam to start
    await examMakerPage.waitForTimeout(2000);

    
// Create test-data directory if it doesn't exist
const testDataDir = './test-data';
if (!fs.existsSync(testDataDir)) {
  fs.mkdirSync(testDataDir, { recursive: true });
}

// Save only exam name to file for other tests to use
const examInfo = {
  examName: examName
};

fs.writeFileSync(
  path.join(testDataDir, 'exam-info.json'), 
  JSON.stringify(examInfo, null, 2)
);

console.log('Exam info saved for other tests');
console.log(`Exam "${examName}" is ready for testing!`);
    
  });

