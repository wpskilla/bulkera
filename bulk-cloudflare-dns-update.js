// npm install axios

const axios = require('axios');

// ✅ Your Cloudflare API Token (edit this)
const CLOUDFLARE_API_TOKEN = 'YOUR_API_TOKEN_HERE';

// ✅ List of domains with respective MX records
const DOMAIN_RECORDS = [
  { domain: 'example1.com', mx: 'mail1.example1.com' },
  { domain: 'example2.net', mx: 'mail2.example2.net' },
  { domain: 'example3.org', mx: 'mail3.example3.org' }
];

// Cloudflare API headers
const headers = {
  Authorization: `Bearer ${CLOUDFLARE_API_TOKEN}`,
  'Content-Type': 'application/json'
};

// Fetch zone info by domain name
async function getZoneByName(domainName) {
  const res = await axios.get(`https://api.cloudflare.com/client/v4/zones?name=${domainName}`, { headers });
  return res.data.result[0];
}

// Get existing MX records
async function getMXRecord(zoneId) {
  const res = await axios.get(`https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records?type=MX`, { headers });
  return res.data.result;
}

// Create new MX record
async function createMXRecord(zoneId, recordData) {
  const res = await axios.post(`https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records`, recordData, { headers });
  return res.data;
}

// Update an existing MX record
async function updateMXRecord(zoneId, recordId, recordData) {
  const res = await axios.put(`https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records/${recordId}`, recordData, { headers });
  return res.data;
}

// Main logic
(async () => {
  try {
    for (const item of DOMAIN_RECORDS) {
      const { domain, mx } = item;
      console.log(`\n🔧 Processing domain: ${domain} → MX: ${mx}`);

      const zone = await getZoneByName(domain);
      if (!zone) {
        console.log(`❌ Zone not found for domain: ${domain}`);
        continue;
      }

      const zoneId = zone.id;
      const recordName = domain; // root domain as MX name

      const mxRecordData = {
        type: 'MX',
        name: recordName,
        content: mx,
        priority: 10,
        ttl: 3600,
        proxied: false
      };

      const existingRecords = await getMXRecord(zoneId);
      const existing = existingRecords.find(r => r.name === recordName && r.type === 'MX');

      if (existing) {
        console.log(`📝 Updating existing MX record...`);
        await updateMXRecord(zoneId, existing.id, mxRecordData);
      } else {
        console.log(`➕ Creating new MX record...`);
        await createMXRecord(zoneId, mxRecordData);
      }

      console.log(`✅ Done with ${domain}`);
    }

    console.log(`\n🎉 All specified domains have been processed successfully.`);
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
})();


// node update-mx-custom.js


// 🔧 Processing domain: example1.com → MX: mail1.example1.com
// 📝 Updating existing MX record...
// ✅ Done with example1.com

// 🔧 Processing domain: example2.net → MX: mail2.example2.net
// ➕ Creating new MX record...
// ✅ Done with example2.net

// 🎉 All specified domains have been processed successfully.
