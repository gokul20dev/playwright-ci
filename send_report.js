import nodemailer from "nodemailer";
import fs from "fs";
import path from "path";

// Get Gmail credentials from environment variables
const user = process.env.GMAIL_USER;
const pass = process.env.GMAIL_PASS;
const subject = process.env.TEST_SUBJECT || "Playwright Test Report";

// Email recipients
const toRecipients = [
  "gopalakrishnan93843@gmail.com",
  "recipient2@example.com"
];

const ccRecipients = [
  "gokulgokul78752@gmail.com"
];

const bccRecipients = [
  "team@example.com"
];

if (!user || !pass) {
  console.error("GMAIL_USER or GMAIL_PASS not set");
  process.exit(1);
}

// Create transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: { user, pass }
});

// Read HTML report from Playwright output
const reportPath = path.resolve("./playwright-report/index.html");

if (!fs.existsSync(reportPath)) {
  console.error("❌ HTML report not found at", reportPath);
  process.exit(1);
}

const reportHtml = fs.readFileSync(reportPath, "utf-8");

// Send email with HTML report as body
await transporter.sendMail({
  from: `"Gopala Krishnan" <${user}>`,
  to: toRecipients.join(","),     // main recipients
  cc: ccRecipients.join(","),     // CC recipients
  bcc: bccRecipients.join(","),   // BCC recipients
  subject: subject,
  html: reportHtml                 // HTML content of report
});

console.log("✅ Email sent successfully to all recipients!");
