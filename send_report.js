import nodemailer from "nodemailer";
import fs from "fs";
import path from "path";

// Gmail credentials from environment
const user = process.env.GMAIL_USER;
const pass = process.env.GMAIL_PASS;
const subject = process.env.TEST_SUBJECT || "✅ Playwright Tests Passed";

// Email recipients
const toRecipients = ["gopalakrishnan93843@gmail.com", "recipient2@example.com"];
const ccRecipients = ["gokulgokul78752@gmail.com"];
const bccRecipients = ["team@example.com"];

if (!user || !pass) {
    console.error("GMAIL_USER or GMAIL_PASS not set");
    process.exit(1);
}

// Create transporter
const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: { user, pass },
});

// Read the Playwright HTML report
const reportPath = path.resolve("./playwright-report/index.html");
if (!fs.existsSync(reportPath)) {
    console.error("❌ HTML report not found at", reportPath);
    process.exit(1);
}
const reportHtml = fs.readFileSync(reportPath, "utf-8");

// Send email with HTML as body
await transporter.sendMail({
    from: `"Playwright CI" <${user}>`,
    to: toRecipients.join(","),
    cc: ccRecipients.join(","),
    bcc: bccRecipients.join(","),
    subject: subject,
    html: reportHtml,   // <-- this renders the report in the email body
});

console.log("✅ HTML report sent successfully!");
