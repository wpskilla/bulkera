// Node.js 18+ has built-in fetch
const API_TOKEN = 'IyP6Twvev32G5-KMpKBi4F_cGbgq4OslYEKUpZi9'; // Replace with your token
const IP = '46.202.194.99'; // Replace with your IP

const DOMAINS = [
  'flooringrepair.co.uk',
  'floorlayers.uk',
  'floorsanding.org.uk',
  'floorscreeders.org.uk',
  'floortilefitters.co.uk',
  'floortilers.co.uk',
  'flytippingremoval.uk',
  'fridge-disposal.co.uk',
  'cladding-spraying.uk',
  'coldchainlogistics.uk',
  'commercialkitchencleaners.uk',
  'chimney-cleaning.uk',
  'chimneyrepair.org.uk',
  'claddingremoval.co.uk',
];

const DNS_RECORDS_TEMPLATE = (domain, ip) => [
  { type: 'A', name: '@', content: ip, proxied: false, ttl: 1 },
];

async function getZoneId(domain) {
  const response = await fetch(`https://api.cloudflare.com/client/v4/zones?name=${domain}`, {
    headers: {
      Authorization: `Bearer ${API_TOKEN}`,
      'Content-Type': 'application/json'
    }
  });

  const data = await response.json();
  if (!data.success || !data.result.length) {
    throw new Error(`Zone not found for ${domain}`);
  }
  return data.result[0].id;
}

async function getDNSRecords(zoneId) {
  const response = await fetch(`https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records?per_page=1000`, {
    headers: {
      Authorization: `Bearer ${API_TOKEN}`,
      'Content-Type': 'application/json'
    }
  });

  const data = await response.json();
  if (!data.success) throw new Error('Failed to fetch DNS records');
  return data.result;
}

async function deleteDNSRecord(zoneId, recordId) {
  const response = await fetch(`https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records/${recordId}`, {
    method: 'DELETE',
    headers: {
      Authorization: `Bearer ${API_TOKEN}`,
      'Content-Type': 'application/json'
    }
  });

  const data = await response.json();
  if (!data.success) throw new Error(`Failed to delete record ${recordId}`);
}

async function createDNSRecord(zoneId, record) {
  const response = await fetch(`https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${API_TOKEN}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(record)
  });

  const data = await response.json();
  if (!data.success) throw new Error(`Failed to create record: ${JSON.stringify(data.errors)}`);
  return data.result;
}

async function setSSLMode(zoneId) {
  const response = await fetch(`https://api.cloudflare.com/client/v4/zones/${zoneId}/settings/ssl`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${API_TOKEN}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ value: 'strict' })
  });

  const data = await response.json();
  if (!data.success) throw new Error(`Failed to update SSL: ${JSON.stringify(data.errors)}`);
}

async function processDomain(domain) {
  console.log(`\n🌐 Processing ${domain}`);
  try {
    const zoneId = await getZoneId(domain);
    
    // Delete existing records
    const records = await getDNSRecords(zoneId);
    console.log(`🗑️ Found ${records.length} records to delete`);
    for (const record of records) {
      await deleteDNSRecord(zoneId, record.id);
      console.log(`   ✅ Deleted ${record.type} ${record.name}`);
    }

    // Create new records
    const newRecords = DNS_RECORDS_TEMPLATE(domain, IP);
    for (const record of newRecords) {
      await createDNSRecord(zoneId, record);
      console.log(`   ✅ Created ${record.type} ${record.name}`);
    }

    // Update SSL
    await setSSLMode(zoneId);
    console.log(`🔒 SSL set to Full Strict`);

    console.log(`✅ ${domain} completed successfully`);
  } catch (error) {
    console.error(`❌ Error processing ${domain}: ${error.message}`);
  }
}

async function main() {
  console.log("🚀 Starting bulk DNS update");
  for (const domain of DOMAINS) {
    await processDomain(domain);
  }
  console.log("\n🎉 All domains processed");
}

main();