
export class ExamMaker {

    constructor(page) {
      this.page = page;
 
      this.createNewExamButton = page.getByRole('button', { name: ' CREATE NEW EXAM' });
      this.examNameInput = page.getByRole('textbox', { name: 'Exam Name * Email Id Pass Code' });
      this.startDateInput = page.getByPlaceholder('Enter Start Date');
      this.startTimeInput = page.getByPlaceholder('Enter Start Time');
      this.durationInput = page.getByPlaceholder('Duration');
      this.shuffleToggle0 = page.locator('#SC span').nth(1);
      this.shuffleToggle1 = page.locator('#basic-settings div').filter({ hasText: 'Email & Communication Send' }).locator('span').nth(1);
      this.shuffleToggle2 = page.locator('#basic-settings div').filter({ hasText: 'Question Organization Shuffle' }).locator('span').nth(1);
      this.shuffleToggle3 = page.locator('#basic-settings div').filter({ hasText: 'Question Organization Shuffle' }).locator('span').nth(3);
      this.shuffleToggle4 = page.locator('div:nth-child(2) > .aesthetic-accordion-header');
      this.shuffleToggle5 = page.locator('#WR span').nth(1);
      this.shuffleToggle6 = page.locator('.setting-card.proctoring-card.master-toggle > .toggle-switch > .slider');
      this.nextButton = page.getByRole('button', { name: 'Next' });
    }
  
    generateExamName() {

      const randomNum = Math.floor(Math.random() * 100);
      return `Automation test ${randomNum}`;
    }
  
    getCurrentDate() {

      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const day = String(now.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    }
  
    getCurrentTime() {

      const now = new Date();
      now.setMinutes(now.getMinutes() + 30);
      
      let hours = now.getHours(); // This line was missing!
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const ampm = hours >= 12 ? 'pm' : 'am';
      hours = hours % 12 || 12;
      return `${hours}:${minutes}${ampm}`;
    }


    async createNewExam(examName = null, startDate = null, startTime = null, duration = '25') {
      
      await this.createNewExamButton.click();
      
      const name = examName || this.generateExamName();
      const date = startDate || this.getCurrentDate();
      const time = startTime || this.getCurrentTime();

        // Store the exam name for later use
    this.createdExamName = name;
    console.log('Creating exam with name:', name);
      
      await this.examNameInput.fill(name);
      await this.startDateInput.fill(date);
      await this.startTimeInput.click();
      await this.page.waitForTimeout(2000);
      await this.startTimeInput.fill(time);
      await this.page.waitForTimeout(3000);
      await this.durationInput.fill(duration);
      // await this.shuffleToggle0.click();
      // await this.shuffleToggle1.click();
      await this.shuffleToggle2.click();
      await this.shuffleToggle3.click();
      // await this.shuffleToggle4.click();
      // await this.shuffleToggle5.click();
      // await this.shuffleToggle6.click();
      await this.nextButton.click();
      return name;
    }
    getCreatedExamName() {
      return this.createdExamName;
    }

// Find and start exam by name
async startExamByName(examName) {
  console.log('Attempting to start exam:', examName);
  
  // Click Today button
  const todayButton = this.page.getByRole('button', { name: 'Today' });
  await todayButton.waitFor({ state: 'visible', timeout: 10000 });
  await todayButton.click();
  
  // Wait for the table to load
  await this.page.waitForTimeout(3000);
  
  // Debug: Log all exam names in the table
  const allExamNames = await this.page.locator('td').allTextContents();
  console.log('All text in table cells:', allExamNames);
  
  // Find the row containing the exam name
  const examRow = this.page.locator('div.ag-row').filter({ 
    hasText: examName 
  });
  
  const rowCount = await examRow.count();
  console.log(`Found ${rowCount} row(s) matching exam name: "${examName}"`);
  
  // if (rowCount === 0) {
  //   throw new Error(`Exam "${examName}" not found in the table`);
  // }
  
  // Step 5: Find and click the action (3 dots) button inside that row
  const actionsButton = examRow.locator('i.bx.bx-dots-vertical-rounded.action-menu-main').first();
  await actionsButton.waitFor({ state: 'visible', timeout: 5000 });
  await actionsButton.click();
  console.log('Clicked actions menu');

  // Step 6: Wait for dropdown to appear dynamically
  const dropdown = this.page.locator('.action-dropdown.drop-down.active');
  await dropdown.waitFor({ state: 'visible', timeout: 5000 });

  // Step 7: Click the Start button
  const startButton = dropdown.locator('.start-stop-btn.act-pointer');
  await startButton.waitFor({ state: 'visible', timeout: 5000 });
  await startButton.click();
  
  console.log(`Clicked Start button for exam: ${examName}`);
  
  // Optional: Wait a bit for the action to complete
  await this.page.waitForTimeout(1000);
}

// Start the last created exam
async startCreatedExam() {
  if (!this.createdExamName) {
    throw new Error('No exam has been created yet. Call createNewExam() first.');
  }
  console.log('Starting the created exam:', this.createdExamName);
  await this.startExamByName(this.createdExamName);
}
  }