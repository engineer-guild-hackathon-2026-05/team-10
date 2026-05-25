const admin = require('firebase-admin');

async function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  try {
    const decoded = await admin.auth().verifyIdToken(header.split(' ')[1]);
    req.uid = decoded.uid;
    req.email = decoded.email ?? null;
    req.displayName = decoded.name ?? null;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
}

module.exports = authMiddleware;
