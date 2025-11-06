import nodemailer from "nodemailer";
import fs from "fs";

// Get Gmail credentials from environment variables
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

// Read HTML report
const reportHtml = fs.readFileSync("./playwright-report/index.html", "utf-8");

// Send email
await transporter.sendMail({
  from: user,
  to: user,
  subject: subject,
  html: reportHtml
});

console.log("✅ Email sent successfully!");
