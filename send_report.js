import nodemailer from "nodemailer";
import fs from "fs";
import path from "path";

async function main() {
    const user = process.env.GMAIL_USER;
    const pass = process.env.GMAIL_PASS;
    const subject = process.env.TEST_SUBJECT || "✅ Playwright Tests Passed";

    const toRecipients = ["gopalakrishnan93843@gmail.com", "gokulcoal78752@gmail.com"];
    const ccRecipients = ["gokulgokul78752@gmail.com"];
    const bccRecipients = ["gokulakrishnan1607@gmail.com"];

    if (!user || !pass) {
        console.error("GMAIL_USER or GMAIL_PASS not set");
        process.exit(1);
    }

    const transporter = nodemailer.createTransport({
        service: "gmail",
        auth: { user, pass },
    });

    const reportHtmlPath = path.resolve("./playwright-report/index.html");
    const reportHtml = fs.existsSync(reportHtmlPath)
        ? fs.readFileSync(reportHtmlPath, "utf-8")
        : "<p>Report not found</p>";

    const zipPath = path.resolve("./playwright-report.zip");
    if (!fs.existsSync(zipPath)) {
        console.error("❌ ZIP report not found at", zipPath);
        process.exit(1);
    }

    await transporter.sendMail({
        from: `"Playwright CI" <${user}>`,
        to: toRecipients.join(","),
        cc: ccRecipients.join(","),
        bcc: bccRecipients.join(","),
        subject: subject,
        html: reportHtml,
        attachments: [
            { filename: "playwright-report.zip", path: zipPath },
        ],
    });

    console.log("✅ Email sent successfully!");
}

main().catch(err => {
    console.error("❌ Failed to send email:", err);
    process.exit(1);
});

