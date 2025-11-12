import nodemailer from "nodemailer";
import fs from "fs";
import path from "path";

// Gmail credentials
const user = process.env.GMAIL_USER;
const pass = process.env.GMAIL_PASS;

// Suite + status
const suite = process.env.TEST_SUITE || "all";
const testStatus = process.env.TEST_STATUS || "Failed";
const subject = `Playwright Test Report - ${suite} (${testStatus})`;

// Paths
const reportPath = path.resolve("playwright-report/index.html");
const reportUrl = process.env.REPORT_URL || null;

// Check if local report exists
let reportExists = false;
try {
  await fs.promises.access(reportPath);
  reportExists = true;
  console.log("✅ Found Playwright HTML report:", reportPath);
} catch {
  console.warn("⚠️ Report not found at:", reportPath);
}

// Configure Gmail SMTP
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: { user, pass },
});

// --- 🧾 Build professional HTML email ---
let emailBody = `
  <div style="font-family: Arial, sans-serif; color: #333; line-height:1.6;">
    <div style="border-bottom:2px solid #007bff; padding-bottom:6px; margin-bottom:12px;">
      <h2 style="color:#007bff; margin:0;">Playwright CI Test Report</h2>
      <p style="margin:4px 0 0 0; font-size:13px; color:#666;">
        Automated report from ${process.env.COMPANY_NAME || "QA Pipeline"}
      </p>
    </div>
`;

// 🔹 Add the "View Report" button if S3 URL exists
if (reportUrl) {
  emailBody += `
    <p>
      <a href="${reportUrl}" target="_blank" rel="noopener noreferrer"
         style="display:inline-block;background:#007bff;color:#fff;
                padding:12px 18px;font-weight:bold;border-radius:8px;
                text-decoration:none;font-size:14px;">
        🔍 View Full HTML Report
      </a>
    </p>
    <p style="font-size:13px;color:#555;margin-top:6px;">
      or copy & paste this link:<br>
      <a href="${reportUrl}" target="_blank" style="color:#007bff;">${reportUrl}</a>
    </p>
  `;
} else {
  emailBody += `
    <p style="color:#d9534f;">⚠️ Report link unavailable — check Jenkins artifacts or S3 permissions.</p>
  `;
}

emailBody += `
    <hr style="border:none;border-top:1px solid #ddd;margin:12px 0;">
    <p><b>Suite:</b> ${suite}</p>
    <p><b>Timestamp:</b> ${new Date().toLocaleString()}</p>
`;

if (reportExists) {
  emailBody += `
    <p style="background:#e8f5e9;padding:8px 10px;border-left:4px solid #4caf50;">
      ✅ The Playwright HTML report is also attached below for offline viewing.
    </p>
  `;
} else {
  emailBody += `
    <p style="background:#fff3cd;padding:8px 10px;border-left:4px solid #ffc107;">
      ⚠️ Local report not found; please use the link above.
    </p>
  `;
}

// --- Simple footer (no contact info) ---
emailBody += `
    <hr style="border:none;border-top:1px solid #ddd;margin:12px 0;">
    <p style="font-size:12px;color:gray;">Sent automatically by Playwright CI</p>
  </div>
`;

// --- ✉️ Compose and send ---
const mailOptions = {
  from: `"Playwright CI" <ci-reports@yourcompany.com>`, // change domain if needed
  to: ["gopalakrishnan93843@gmail.com", "gokulcoal78752@gmail.com"],
  cc: ["gokulgokul78752@gmail.com"],
  bcc: ["gokulakrishnan1607@gmail.com"],
  subject,
  html: emailBody,
};

// Attach the HTML report (if exists)
if (reportExists) {
  mailOptions.attachments = [
    {
      filename: "playwright-report.html",
      path: reportPath,
      contentType: "text/html",
    },
  ];
}

// --- Send email ---
try {
  await transporter.sendMail(mailOptions);
  console.log("✅ Email sent successfully with S3 link + attachment!");
} catch (err) {
  console.error("❌ Failed to send email:", err.message);
  pro
