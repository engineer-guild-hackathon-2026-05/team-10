const admin = require('firebase-admin');
const { seedHowCardsIfNeeded } = require('../seed/howCardSeedData');

admin.initializeApp();

seedHowCardsIfNeeded(admin.firestore(), admin.firestore.FieldValue, {
  force: process.argv.includes('--force'),
})
  .then(result => {
    const action = result.seeded ? 'seeded' : 'skipped';
    console.log(`${action} ${result.count} how-cards (${result.version})`);
  })
  .catch(error => {
    console.error(error);
    process.exitCode = 1;
  });
