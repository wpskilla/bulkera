// No need to import fetch in Node.js 18+
// comment => node cloudflare-bulk.js
const EMAIL = 'mail@gmail.com'; // Optional: not used in token-based auth
const API_TOKEN = 'tokendsfsdfsdfs23423423';
const IP = '34.3534.453.23424';

// Domains to process
const DOMAINS = [
  'thermalimaging.org.uk',
  'thermostatinstallation.co.uk',
  'tidyingservice.co.uk',
  'tilefitting.co.uk',
];

// DNS records template
const DNS_RECORDS_TEMPLATE = (domain, ip) => [
  { type: 'A', name: '@', content: ip, proxied: true, ttl: 1 },
  { type: 'CNAME', name: 'www', content: domain, proxied: true, ttl: 1 }
];

// Fetch zone ID
async function getZoneId(domain) {
  const res = await fetch(`https://api.cloudflare.com/client/v4/zones?name=${domain}`, {
    headers: {
      'Authorization': `Bearer ${API_TOKEN}`,
      'Content-Type': 'application/json'
    }
  });

  const data = await res.json();
  if (!data.success || data.result.length === 0) {
    throw new Error(`Zone not found for ${domain}`);
  }

  return data.result[0].id;
}

// Create DNS record
async function createDNSRecord(zoneId, record) {
  const res = await fetch(`https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${API_TOKEN}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(record)
  });

  const data = await res.json();
  if (!data.success) {
    throw new Error(`Failed to create record: ${JSON.stringify(data.errors)}`);
  }

  return data.result;
}

// Set SSL to Full (Strict)
async function setSSLMode(zoneId) {
  const res = await fetch(`https://api.cloudflare.com/client/v4/zones/${zoneId}/settings/ssl`, {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${API_TOKEN}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ value: 'strict' }) // "strict" = Full (strict)
  });

  const data = await res.json();
  if (!data.success) {
    throw new Error(`Failed to update SSL setting: ${JSON.stringify(data.errors)}`);
  }

  console.log(`🔒 SSL set to Full (strict)`);
}

// Process one domain
async function processDomain(domain) {
  console.log(`🌐 Processing ${domain}...`);
  try {
    const zoneId = await getZoneId(domain);
    
    // Set SSL to Full Strict
    await setSSLMode(zoneId);

    // Create DNS records
    const records = DNS_RECORDS_TEMPLATE(domain, IP);
    for (const record of records) {
      await createDNSRecord(zoneId, record);
      console.log(`✅ Created ${record.type} record for ${record.name}.${domain}`);
    }

    console.log(`✅ Finished ${domain}\n`);
  } catch (err) {
    console.error(`❌ Error for ${domain}: ${err.message}`);
  }
}

// Main function
async function main() {
  console.log("🚀 Starting domain configuration...\n");
  for (const domain of DOMAINS) {
    await processDomain(domain);
  }
  console.log("🎉 All domains processed.");
}

main();
