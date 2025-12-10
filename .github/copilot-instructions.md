## Quick orientation

This repository implements PowerPass — a cross-platform secret storage system with multiple editions: AES (cross-platform), DPAPI (Windows), TPM (work-in-progress) and a Web edition (TypeScript/localStorage). The codebase mixes PowerShell, C# (compiled via Add-Type at runtime), and a small TypeScript/web UI.

Use this file to help an AI coding agent get productive quickly: major components, developer flows, file locations, and important gotchas discovered in the code.

---

## Repository structure (the purpose of each directory)

- The root directory contains the deployment script, the license, code formatting rules, the readme, the repository directory, and a test KeePass database
- `.github` - contains this instruction manual for Copilot
- `Build` - a temporary directory created when compiling the KeePassLib assembly when building a release using the `util/Build-Release.ps1` - this is marked ignored inside the `.gitignore` file at the root
- `docs` - online documentation in markdown format. These files are published to https://chopinrlz.github.io/powerpass/ by Github whenever a commit is made.
- `KeePassLib` - source code for the KeePass 2 library written in C# and downloaded from https://keepass.info/download.html
- `module` - source code for the two principal PowerPass editions (AES and DPAPI) written in PowerShell
- `test` - scripts and artifacts for unit testing PowerPass before creating a release
- `tpm` - source code for the TPM edition of PowerPass written in C and using the tpm2-tss library for TPM I/O
- `ts` - source code for the web browser edition of PowerPass written in TypeScript
- `util` - utility scripts for doing research, configuring access to GitHub, and building releases of PowerPass AES and DPAPI editions

## Big picture (what talks to what)

- PowerShell module (module/*.ps1) is the canonical runtime for the native editions. It compiles/loads small C# helpers at runtime with `Add-Type` (see `module/AesCrypto.cs`, `module/Compression.cs`, `module/Conversion.cs`).
- `AesCrypto.cs` implements file encryption/decryption used by the PowerShell module. Files are encrypted with AES and the IV is written as raw bytes at the start of the file. See `AesCrypto.Encrypt`/`Decrypt` for the exact layout.
- `module/PowerPass.Aes.psm1` orchestrates locker lifecycle: key generation, reading/writing lockers, attachments handling, and uses `AesCrypto` for crypto operations. `PowerPass.Common.ps1` holds common helpers. This is the AES edition of PowerPass.
- `module/PowerPass.DpApi.psm1` implements locker lifecycle: key generation, reading/writing lockers, attachments, and also interfaces with KeePass 2 databases. `PowerPass.Common.ps1` holds common helpers. This is the DPAPI edition of PowerPass.
- Web edition (in `ts/`) is a lightweight JavaScript-based edition of PowerPass that runs entirely in your web browser client-side: `ts/index.html` is the entry point for this edition which includes the HTML required to render the UI. `ts/powerpass.ts` defines the Secret types and a `PowerPassLocker` for localStorage-based lockers (web crypto is used in the TS implementation). `ts/ux.ts` defines the front-end controller logic for the HTML controls and implements the application layer of operations that occur when users interact with PowerPass. Several JavaScript libraries are incorporated including `ts/jquery-3.7.1.js` for jQuery support, `ts/rivets.js` for data binding the PowerPass objects to HTML controls, `ts/sightglass.js` for observable adapters which watch for changes and perform actions, `ts/require.min.js` the RequireJS library for loading script dependencies dynamicslly, and finally `ts/config.ts` which instructs RequireJS to require the `ts/ux.ts` dependency.
- Release/build: `util/Build-Release.ps1` is a Windows PowerShell v5-only script that compiles the C# sources to assemblies and packages a release zip/tar.gz of both the AES and DPAPI editions of PowerPass for upload to Github on the main page https://github.com/chopinrlz/powerpass. Deployment uses `Deploy-PowerPass.ps1` at repo root to deploy either the AES or DPAPI edition of PowerPass to the local user's environment. There is currently no deployment script for the TPM edition or the Web edition of PowerPass.

---

## Key files to reference when making changes

- `module/AesCrypto.cs` — canonical AES implementation and file format (IV prefix). Very important if you modify encryption semantics.
- `module/PowerPass.Aes.psm1` — main PowerShell module runtime for AES edition; shows locker lifecycle and attachments handling.
- `module/PowerPass.Common.ps1` — shared helpers (locker initialization, conversion helpers, ephemeral key logic).
- `ts/powerpass.ts` — web edition entry: Secret type, Locker, and the place where web encryption/decryption lives.
- `util/Build-Release.ps1` — how to build a release; requires Windows PowerShell 5 and csc.exe in the runtime directory.
- `test/` — example scripts (e.g., `Test-AesCrypto.ps1`) that demonstrate runtime behavior and are good starting points for changes.
- `docs/` — online documentation for PowerPass in markdown format with images for decoration. Changes here are automatically deployed to https://chopinrlz.github.io/powerpass/ after pushing commits to Github. The README.md file is the default document for the online documentation.

---

## Important data & crypto formats (practical details)

- Native file encryption (AesCrypto): the IV is written to the file first (raw bytes), then the ciphertext. Consumers in this repo expect that layout (see `AesCrypto.Encrypt`/`Decrypt`).
- Padded passphrase: `AesCrypto.CreatePaddedKey(secret)` accepts passphrases between 4 and 32 chars and pads/repeats bytes to 32 bytes. Changing that will break disk key compatibility.
- Ephemeral key derivation: `Get-PowerPassEphemeralKey` builds a composite of hostname|username|domain|MAC hashed with SHA-256. Locker key files and key rotation depend on this behavior.
- Attachments: stored as base64 (`attachment.Data`) and optionally gzipped (`attachment.GZip`). PowerShell cmdlets detect and decompress when needed — keep that behavior when editing attachments.
- Web edition: `ts/powerpass.ts` uses the browser Web Crypto API and stores a JSON payload (iv + base64 ciphertext) for encrypted lockers in localStorage. This payload is intentionally different from native binary file format; treat web ↔ native interchange explicitly.

---

## Developer workflows & commands (concrete)

- Release (Windows PowerShell 5 only): run `.\util\Build-Release.ps1` from the repo root inside Windows PowerShell 5. The script requires `csc.exe` available in the runtime directory and will compile `KeePassLib` and the module C# files before packaging.
- Deploy locally: run `.\Deploy-PowerPass.ps1` from the repo root in a PowerShell session to install the module for immediate use.
- PowerShell tests & demos: run scripts in `test/` (e.g., `.test\Test-AesCrypto.ps1`) from a PowerShell session with the module installed or from repo root after running `Deploy-PowerPass.ps1`.
- TypeScript/web: compile TS before testing web UI: `npx tsc -p ts/tsconfig.json`. Then open `ts/index.html` in a modern browser to test the web edition.

Notes on environment: the release script explicitly requires Windows PowerShell v5 and the .NET C# compiler (`csc.exe`). CI on non-Windows will not run `util/Build-Release.ps1` without platform-specific changes.

---

## Project-specific conventions & gotchas

- Mixed runtimes: PowerShell scripts compile and use C# helpers at runtime (`Add-Type`), so changing C# sources affects module behavior immediately when re-imported.
- Field name casing differs across runtimes. PowerShell secrets use PascalCase (Title, UserName, Password) while TypeScript uses lower-case fields (`title`, `username`, `password`). When importing/exporting JSON between editions, map fields explicitly.
- Changing encryption formats or passphrase padding will break existing lockers — include migration paths when making such changes.
- The web edition stores its locker under `localStorage.getItem('powerpass')` (see `ts/powerpass.ts:init()`), so front-end tests can be run by setting/clearing that key.

---

## Suggested first tasks for agents/contributors

- Make `ts/powerpass.ts` initialization explicit/async: `init()` currently calls an async decrypt without awaiting; consider making initialization asynchronous (careful: callers may rely on synchronous behavior).
- Implement a cross-edition import/export that maps field names and optionally converts formats (native IV-prefixed binary <-> web JSON payload).

---