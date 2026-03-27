#!/usr/bin/env node
/**
 * v0 Design Generator
 * Generates UI components/pages via v0.dev API and saves files locally.
 * 
 * Usage: V0_API_KEY=... node v0-generate.js --prompt "..." --output ./output-dir [--follow-up "..."]
 */

const { v0 } = require('v0-sdk');
const fs = require('fs');
const path = require('path');

async function main() {
  const args = process.argv.slice(2);
  
  let prompt = '';
  let outputDir = './v0-output';
  let followUps = [];
  let chatId = null;
  
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--prompt' || args[i] === '-p') prompt = args[++i];
    else if (args[i] === '--output' || args[i] === '-o') outputDir = args[++i];
    else if (args[i] === '--follow-up' || args[i] === '-f') followUps.push(args[++i]);
    else if (args[i] === '--chat-id') chatId = args[++i];
  }

  if (!prompt && !chatId) {
    console.error('Usage: v0-generate.js --prompt "..." --output ./dir [--follow-up "..."]');
    process.exit(1);
  }

  if (!process.env.V0_API_KEY) {
    console.error('ERROR: V0_API_KEY environment variable required');
    process.exit(1);
  }

  try {
    let chat;
    
    if (chatId) {
      // Continue existing chat
      console.log(`Continuing chat ${chatId}...`);
      const response = await v0.chats.sendMessage({ chatId, message: prompt || followUps[0] });
      chat = response;
    } else {
      // Create new chat
      console.log('Creating v0 chat...');
      console.log('Prompt:', prompt.substring(0, 200) + (prompt.length > 200 ? '...' : ''));
      chat = await v0.chats.create({ message: prompt });
    }

    console.log('Chat ID:', chat.id);
    console.log('Web URL:', chat.url || chat.webUrl);
    console.log('Demo URL:', chat.demo);
    
    // Send follow-up messages
    for (const followUp of followUps) {
      console.log('\nSending follow-up:', followUp.substring(0, 100));
      chat = await v0.chats.sendMessage({ chatId: chat.id, message: followUp });
    }

    // Extract and save files
    const files = chat.latestVersion?.files || chat.files || [];
    console.log(`\nFiles generated: ${files.length}`);
    
    fs.mkdirSync(outputDir, { recursive: true });
    
    const manifest = {
      chatId: chat.id,
      webUrl: chat.url || chat.webUrl,
      demoUrl: chat.demo,
      files: []
    };

    for (const file of files) {
      const fileName = file.name || file.meta?.file;
      const content = file.content || file.source;
      
      if (!fileName || !content) continue;
      
      const filePath = path.join(outputDir, fileName);
      fs.mkdirSync(path.dirname(filePath), { recursive: true });
      fs.writeFileSync(filePath, content);
      
      manifest.files.push({
        name: fileName,
        path: filePath,
        size: content.length
      });
      
      console.log(`  ✓ ${fileName} (${content.length} chars)`);
    }

    // Save manifest
    fs.writeFileSync(
      path.join(outputDir, 'v0-manifest.json'),
      JSON.stringify(manifest, null, 2)
    );
    
    console.log(`\nManifest saved to ${outputDir}/v0-manifest.json`);
    console.log('Done!');
    
    // Output JSON for programmatic use
    console.log('\n---JSON_OUTPUT---');
    console.log(JSON.stringify(manifest));

  } catch (error) {
    console.error('ERROR:', error.message);
    if (error.response) {
      console.error('Response:', JSON.stringify(error.response.data || error.response));
    }
    process.exit(1);
  }
}

main();
