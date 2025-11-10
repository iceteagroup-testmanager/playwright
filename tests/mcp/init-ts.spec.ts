/**
 * Copyright (c) Microsoft Corporation.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { test, expect } from './fixtures';
import fs from 'fs';


for (const context of ['isolated', 'persistent']) {
  test(`--init-ts option loads and executes TypeScript script (${context})`, async ({ startClient, server }, testInfo) => {
    // Create a temporary TypeScript init script
    const initTsPath = testInfo.outputPath('init-script1.ts');
    const initTsContent1 = `
      interface Window {
        testInitTsExecuted?: boolean;
      }
      (window as any).testInitTsExecuted = true;
    `;
    await fs.promises.writeFile(initTsPath, initTsContent1);

    const initTsPath2 = testInfo.outputPath('init-script2.ts');
    const initTsContent2 = `console.log('Init TypeScript executed successfully');`;
    await fs.promises.writeFile(initTsPath2, initTsContent2);

    // Start the client with the init-ts option
    const { client: client } = await startClient({
      args: [`--init-ts=${initTsPath}`, `--init-ts=${initTsPath2}`, ...(context === 'isolated' ? ['--isolated'] : [])]
    });

    // Navigate to a page and verify the init script was executed
    await client.callTool({
      name: 'browser_navigate',
      arguments: { url: server.HELLO_WORLD },
    });

    await client.callTool({
      name: 'browser_evaluate',
      arguments: { function: '() => console.log("Custom log")' }
    });

    // Check that the init script variables are available
    expect(await client.callTool({
      name: 'browser_evaluate',
      arguments: { function: '() => window.testInitTsExecuted' }
    })).toHaveResponse({
      result: 'true',
    });

    expect(await client.callTool({
      name: 'browser_console_messages',
    })).toHaveResponse({
      result: expect.stringMatching(/Init TypeScript executed successfully.*Custom log/ms),
    });
  });
}

test('--init-ts option with non-existent file throws error', async ({ startClient }, testInfo) => {
  const nonExistentPath = testInfo.outputPath('non-existent-script.ts');

  // Attempting to start with a non-existent init-ts script should fail
  await expect(startClient({
    args: [`--init-ts=${nonExistentPath}`]
  })).rejects.toThrow();
});

test('--init-ts and --init-script can be used together', async ({ startClient, server }, testInfo) => {
  // Create a JavaScript init script
  const initScriptPath = testInfo.outputPath('init-script.js');
  const initScriptContent = `window.testJsExecuted = true;`;
  await fs.promises.writeFile(initScriptPath, initScriptContent);

  // Create a TypeScript init script
  const initTsPath = testInfo.outputPath('init-script.ts');
  const initTsContent = `
    interface Window {
      testTsExecuted?: boolean;
    }
    (window as any).testTsExecuted = true;
  `;
  await fs.promises.writeFile(initTsPath, initTsContent);

  // Start the client with both init-script and init-ts options
  const { client: client } = await startClient({
    args: [`--init-script=${initScriptPath}`, `--init-ts=${initTsPath}`, '--isolated']
  });

  // Navigate to a page
  await client.callTool({
    name: 'browser_navigate',
    arguments: { url: server.HELLO_WORLD },
  });

  // Check that both JS and TS init scripts were executed
  expect(await client.callTool({
    name: 'browser_evaluate',
    arguments: { function: '() => window.testJsExecuted' }
  })).toHaveResponse({
    result: 'true',
  });

  expect(await client.callTool({
    name: 'browser_evaluate',
    arguments: { function: '() => window.testTsExecuted' }
  })).toHaveResponse({
    result: 'true',
  });
});
