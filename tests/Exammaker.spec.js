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
  
  // Create exam and store the generated name
  const examName = await examMaker.createNewExam();
  console.log('Created exam with name:', examName);
  
  await examMakerPage.waitForTimeout(2000);
  
  examMakerPage.setDefaultTimeout(15000);
  
  // Import questions from Excel
  const questionsFile = path.join(os.homedir(), 'Downloads', 'question_template.xlsx');
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
  await uploadChoiceAttachment(10, 'choice-attachment-container-10-B', 'img.png');
  await uploadChoiceAttachment(13, 'choice-attachment-container-13-B', 'images1.jpeg');
  await uploadChoiceAttachment(18, 'choice-attachment-container-18-B', 'image4.png'); 
  await uploadChoiceAttachment(22, 'choice-attachment-container-22-B', 'images3.jpeg');

  // Question 25
  await examMakerPage.getByText('Question25 ▼ Map').click();
  await examMakerPage.locator('#attachment-container-25').click();
  const file25 = examMakerPage.locator('(//div[@class="dropzone-content"]//input[@type="file"])[1]');
  await file25.setInputFiles(path.join(os.homedir(), 'Downloads', 'image.png'));
  await examMakerPage.locator('#attachmentPanel').getByRole('button', { name: 'Close' }).waitFor({ state: 'visible' });
  await examMakerPage.locator('#attachmentPanel').getByRole('button', { name: 'Close' }).click();
  
  // Question 30 - PDF upload
  await examMakerPage.getByText('Question30 ▼ Map').click();
  await examMakerPage.locator('#attachment-container-30 i').click();
  const file30 = examMakerPage.locator('//div[@class="dropzone-content"]//input[@type="file"]').first();
  await file30.setInputFiles(path.join(os.homedir(), 'Downloads', 'karthik report.pdf'));
  await examMakerPage.locator('#attachmentPanel').getByRole('button', { name: 'Close' }).waitFor({ state: 'visible' });
  await examMakerPage.locator('#attachmentPanel').getByRole('button', { name: 'Close' }).click();
  
  await uploadQuestionAttachment(35, 'attachment-container-35', 'dev123 report.pdf');
  await uploadQuestionAttachment(40, 'attachment-container-40', 'dev123 report.pdf');
  await uploadQuestionAttachment(49, 'attachment-container-49', 'Audio1.mp3');
  
  // Navigate to next step
  await examMakerPage.getByRole('button', { name: 'Next' }).click();
  await examMakerPage.getByLabel('Preview Questions').getByRole('button', { name: 'Next' }).click();
  
    // Add students
    const students = [
      { email: 'student01@gmail.com', passcode: '123' },
      { email: 'student02@gmail.com', passcode: '123' },
    ];

    for (const student of students) {
      await examMakerPage.getByRole('textbox', { name: 'Enter Email Id' }).fill(student.email);
      await examMakerPage.getByRole('textbox', { name: 'Enter Pass Code' }).fill(student.passcode);
      await examMakerPage.getByRole('button', { name: 'Add' }).click();

      try{
        await examMakerPage.waitForSelector('text=Email added successfully', { timeout: 5000 });
        } catch (e) {
          console.log(`Success message not visible, continuing...`);
        }
    }


  // // Import attendees
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
  

  // // Wait for upload confirmation
  // try{
  // await examMakerPage.waitForSelector('text=Successfully imported 30 attendees', { timeout: 10000 });
  // } catch (e) {
  //   console.log(`Success message not visible, continuing...`);
  // }


  // Finalize exam
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
  


    // Save exam name to file for other tests to use
    fs.writeFileSync('./test-data/exam-info.json', JSON.stringify({ 
      examName: examName,
      createdAt: new Date().toISOString()
    }));
    
    console.log('Exam info saved for other tests');

});
