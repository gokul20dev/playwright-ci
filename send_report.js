import nodemailer from "nodemailer";
import fs from "fs";

// Gmail credentials from environment
const user = process.env.GMAIL_USER;
const pass = process.env.GMAIL_PASS;
const subject = process.env.TEST_SUBJECT || "Playwright Test Report";

if (!user || !pass) {
  console.error("GMAIL_USER or GMAIL_PASS not set");
  process.exit(1);
}

// Create transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: { user, pass }
});

// Send email with report as attachment
await transporter.sendMail({
  from: `"Playwright CI" <${user}>`,
  to: user,
  subject: subject,
  text: "Playwright Test Report attached.",
  attachments: [
    {
      filename: "playwright-report.zip",
      path: "./playwright-report.zip"
    }
  ]
});

console.log("✅ Email with report attachment sent successfully!");
