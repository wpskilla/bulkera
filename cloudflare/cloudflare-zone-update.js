const API_TOKEN = 'IyP6Twvev32G5-KMpKBi4F_cGbgq4OslYEKUpZi9';
const IP = '46.202.194.99';

const DOMAINS = [
  'shelvinginstallation.co.uk',
  'shelvinginstallation.uk',
  'shop-front-spraying.uk',
  'showermouldremoval.co.uk',
  'showerresealing.co.uk',
  'signwriting.org.uk',
];

const DNS_RECORDS_TEMPLATE = (domain, ip) => [
  { type: 'A', name: '@', content: ip, proxied: false, ttl: 1 },
  // { type: 'CNAME', name: 'www', content: domain, proxied: false, ttl: 1 }
];

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

async function getAllRecords(zoneId) {
  const res = await fetch(
    `https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records`,
    {
      headers: {
        'Authorization': `Bearer ${API_TOKEN}`,
        'Content-Type': 'application/json'
      }
    }
  );
  
  const data = await res.json();
  return data.success ? data.result : [];
}

async function deleteRecord(zoneId, recordId) {
  const res = await fetch(
    `https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records/${recordId}`,
    {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${API_TOKEN}`,
        'Content-Type': 'application/json'
      }
    }
  );
  
  const data = await res.json();
  if (!data.success) {
    throw new Error(`Failed to delete record: ${JSON.stringify(data.errors)}`);
  }
  return true;
}

async function createRecord(zoneId, record) {
  const res = await fetch(
    `https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${API_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(record)
    }
  );
  
  const data = await res.json();
  if (!data.success) {
    throw new Error(`Failed to create record: ${JSON.stringify(data.errors)}`);
  }
  return true;
}

async function processDomain(domain) {
  console.log(`\n🌐 Starting processing for ${domain}`);
  try {
    // Get Zone ID
    const zoneId = await getZoneId(domain);

    // Get all existing records
    const allRecords = await getAllRecords(zoneId);

    // Identify records to delete
    const recordsToDelete = allRecords.filter(record => 
      (record.type === 'A' && record.name === domain) || // Root A record
      (record.type === 'CNAME' && record.name === `www.${domain}`) // www CNAME
    );

    // Delete old records
    for (const record of recordsToDelete) {
      await deleteRecord(zoneId, record.id);
    }

    // Add propagation delay
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Create new records
    const newRecords = DNS_RECORDS_TEMPLATE(domain, IP).map(record => ({
      ...record,
      name: record.name === '@' ? domain : record.name
    }));

    for (const record of newRecords) {
      await createRecord(zoneId, record);
    }
    console.log(`✅ Records Updated.`);

    console.log(`🎉 Finished processing ${domain}\n`);
  } catch (err) {
    console.error(`❌ Critical error for ${domain}: ${err.message}`);
    console.error('🛑 Stack trace:', err.stack);
  }
}

async function main() {
  console.log("🚀 Starting Cloudflare DNS bulk configuration");
  
  try {
    for (const domain of DOMAINS) {
      await processDomain(domain);
    }
    console.log("✅ All domains processed successfully");
  } catch (err) {
    console.error("💥 Catastrophic failure:", err);
    process.exit(1);
  }
}

// Run the script
main();