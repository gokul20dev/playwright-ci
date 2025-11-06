import nodemailer from "nodemailer";
import fs from "fs";
import path from "path";

// Gmail credentials from environment variables
const user = process.env.GMAIL_USER;
const pass = process.env.GMAIL_PASS;
const subject = process.env.TEST_SUBJECT || "Playwright Test Report";

// Ensure HTML report exists
const reportPath = path.resolve("./playwright-report/index.html");
if (!fs.existsSync(reportPath)) {
  console.error("❌ Playwright HTML report not found at", reportPath);
  process.exit(1);
}

// Read the HTML report
const reportHtml = fs.readFileSync(reportPath, "utf-8");

// Configure Gmail transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: { user, pass },
});

// Send email
await transporter.sendMail({
  from: `"Playwright CI" <${user}>`,
  to: user, // or a list of recipients
  subject,
  html: reportHtml, // Embed HTML content directly
});

console.log("✅ Email sent with HTML report!");
