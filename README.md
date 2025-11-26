# rar

A Flutter plugin for handling RAR archives on **all platforms**: Android, iOS, Linux, macOS, Windows, and Web.

This plugin allows you to extract RAR files, list their contents, and supports password-protected archives.

## Features

- Extract RAR files (v4 and v5 formats)
- List contents of RAR files
- Support for password-protected RAR archives
- Cross-platform support:
  - **Android**: Uses JUnRar (Java)
  - **iOS**: Uses UnrarKit (Objective-C)
  - **Linux/macOS/Windows**: Uses libarchive via native FFI
  - **Web**: Uses WASM-based archive library via JS interop

## Platform Support

| Platform | Extract | List | Password |
|----------|---------|------|----------|
| Android  | ✅      | ✅   | ✅       |
| iOS      | ✅      | ✅   | ✅       |
| Linux    | ✅      | ✅   | ✅       |
| macOS    | ✅      | ✅   | ✅       |
| Windows  | ✅      | ✅   | ✅       |
| Web      | ✅      | ✅   | ✅       |

## Getting Started

### Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  rar: ^0.2.0
```

### Desktop Dependencies

For desktop platforms, you need to install libarchive:

**Linux (Debian/Ubuntu):**
```bash
sudo apt install libarchive-dev
```

**Linux (Fedora/RHEL):**
```bash
sudo dnf install libarchive-devel
```

**macOS:**
```bash
brew install libarchive
```

**Windows:**
```bash
vcpkg install libarchive:x64-windows
```

### Web Dependencies

For web platform, the plugin automatically loads the required WASM library from CDN. No additional setup is required.

## Usage

### Extracting a RAR file

```dart
import 'package:rar/rar.dart';

Future<void> extractRarFile() async {
  final result = await Rar.extractRarFile(
    rarFilePath: '/path/to/archive.rar',
    destinationPath: '/path/to/destination/folder',
    password: 'optional_password', // Optional
  );

  if (result['success']) {
    print('Extraction successful: ${result['message']}');
  } else {
    print('Extraction failed: ${result['message']}');
  }
}
```

### Listing RAR contents

```dart
import 'package:rar/rar.dart';

Future<void> listRarContents() async {
  final result = await Rar.listRarContents(
    rarFilePath: '/path/to/archive.rar',
    password: 'optional_password', // Optional
  );

  if (result['success']) {
    print('Files in archive:');
    for (final file in result['files']) {
      print('- $file');
    }
  } else {
    print('Failed to list contents: ${result['message']}');
  }
}
```

### Web Platform Notes

On the web platform, file system access is limited. The plugin uses a virtual file system approach:

1. When selecting files via a file picker, use `withData: true` to get file bytes
2. Store the file data using `RarWeb.storeFileData(path, bytes)`
3. Extracted files are stored in the virtual file system and can be accessed via `RarWeb.getFileData(path)`

```dart
import 'package:rar/rar.dart';

// On web, store file bytes before extraction
if (kIsWeb) {
  RarWeb.storeFileData('archive.rar', fileBytes);
}

final result = await Rar.extractRarFile(
  rarFilePath: 'archive.rar',
  destinationPath: '/extracted',
);

// On web, get extracted file bytes
if (kIsWeb && result['success']) {
  final extractedData = RarWeb.getFileData('/extracted/file.txt');
}
```

## API Reference

### Rar.extractRarFile

```dart
static Future<Map<String, dynamic>> extractRarFile({
  required String rarFilePath,
  required String destinationPath,
  String? password,
})
```

Extracts a RAR file to a destination directory.

**Parameters:**
- `rarFilePath`: Path to the RAR file
- `destinationPath`: Directory where files will be extracted
- `password`: Optional password for encrypted archives

**Returns:** A map containing:
- `success` (bool): Whether the extraction was successful
- `message` (String): Status message or error description

### Rar.listRarContents

```dart
static Future<Map<String, dynamic>> listRarContents({
  required String rarFilePath,
  String? password,
})
```

Lists all files in a RAR archive.

**Parameters:**
- `rarFilePath`: Path to the RAR file
- `password`: Optional password for encrypted archives

**Returns:** A map containing:
- `success` (bool): Whether the listing was successful
- `message` (String): Status message or error description
- `files` (List<String>): List of file names in the archive

## Note on Creating RAR Archives

Creating RAR archives is **not supported** in this plugin because:

1. RAR is a proprietary format, and creating RAR archives requires proprietary tools
2. The RAR compression algorithm is licensed and cannot be freely used for compression
3. Only decompression is allowed under the UnRAR license

For creating archives, consider using the ZIP format instead, which has better native support across all platforms.

## Error Handling

The plugin returns descriptive error messages for common issues:

- **File not found**: The specified RAR file doesn't exist
- **Bad password**: Incorrect password or password required for encrypted archive
- **Bad archive**: Corrupt or invalid RAR file
- **Unknown format**: File is not a valid RAR archive
- **Bad data**: CRC check failed (data corruption)

## License

This plugin is released under the MIT License.

## Third-party Libraries

This plugin uses the following libraries:

| Platform | Library | License |
|----------|---------|---------|
| Android | [JUnRar](https://github.com/junrar/junrar) | LGPL-3.0 |
| iOS | [UnrarKit](https://github.com/abbeycode/UnrarKit) | BSD |
| Desktop | [libarchive](https://libarchive.org/) | BSD |
| Web | [libarchive.js](https://github.com/nicolo-ribaudo/libarchive.js) | MIT |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Issues

If you find a bug or want to request a new feature, please open an issue on [GitHub](https://github.com/lkrjangid1/rar/issues).
