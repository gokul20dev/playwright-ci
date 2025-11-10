export class Loginpage {
  constructor(page, baseUrl) {
    this.page = page;
    this.baseURL = baseUrl;

    this.collegeCodeInput = page.getByRole('textbox', { name: 'College Code' });
    this.goSendButton = page.getByRole('button', { name: 'Go Send' });
    this.emailInput = page.getByRole('textbox', { name: 'Email address' });
    this.passwordInput = page.getByRole('textbox', { name: 'Password' });
    this.loginButton = page.getByRole('button', { name: 'Login' });
    this.examMakerLink = page.getByRole('link', { name: ' Exam Maker For faculty to' });
  }

  async login(collegeCode, email, password) {
    await this.page.goto(this.baseURL);
    await this.collegeCodeInput.fill(collegeCode);
    await this.page.waitForTimeout(5000);
    await this.goSendButton.click();
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.loginButton.click();
  }

  async navigateToExamMaker() {
    const pagePromise = this.page.waitForEvent('popup');
    await this.examMakerLink.click();
    return await pagePromise;
  }
}