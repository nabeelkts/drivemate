const nodemailer = require('nodemailer');

module.exports = async function handler(req, res) {
  // CORS configuration
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST,OPTIONS');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization'
  );

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // Basic API key protection
  const authHeader = req.headers.authorization;
  const secretKey = process.env.API_SECRET_KEY;
  
  if (!secretKey) {
    console.error('API_SECRET_KEY is not configured on the server');
    return res.status(500).json({ error: 'Server configuration error' });
  }

  if (!authHeader || authHeader !== `Bearer ${secretKey}`) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const { to, subject, htmlContent, attachments } = req.body;

  if (!to || !subject || !htmlContent) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const gmailEmail = process.env.GMAIL_EMAIL;
  const gmailPassword = process.env.GMAIL_APP_PASSWORD;

  if (!gmailEmail || !gmailPassword) {
    console.error('Gmail credentials are not configured on the server');
    return res.status(500).json({ error: 'Server emailing configuration error' });
  }

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: gmailEmail,
      pass: gmailPassword,
    },
  });

  try {
    const info = await transporter.sendMail({
      from: `"Drivemate" <${gmailEmail}>`,
      to,
      subject,
      html: htmlContent,
      attachments: attachments || [],
    });
    return res.status(200).json({ success: true, messageId: info.messageId });
  } catch (error) {
    console.error('Error sending email:', error);
    return res.status(500).json({ error: error.message });
  }
};
