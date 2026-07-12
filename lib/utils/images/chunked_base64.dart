import 'dart:convert';
import 'dart:io';

/// Chunk size for incremental base64 encoding. Must be a multiple of 3 so
/// that every chunk except the last encodes without '=' padding — otherwise
/// concatenating the chunks produces an invalid base64 string.
const int base64ChunkSize = 258048; // 3 * 86016 (~252KB)

/// Encodes [file] to base64 by reading it in [base64ChunkSize] chunks,
/// keeping peak memory bounded for large files.
Future<String> encodeFileToBase64InChunks(File file) async {
  final fileSize = await file.length();
  final chunks = <String>[];

  final randomAccessFile = await file.open();
  try {
    int position = 0;
    while (position < fileSize) {
      final remainingBytes = fileSize - position;
      final currentChunkSize =
          remainingBytes < base64ChunkSize ? remainingBytes : base64ChunkSize;

      final chunkBytes = await randomAccessFile.read(currentChunkSize);
      chunks.add(base64Encode(chunkBytes));

      // Clear chunk bytes from memory
      chunkBytes.fillRange(0, chunkBytes.length, 0);

      position += currentChunkSize;
    }

    return chunks.join('');
  } finally {
    await randomAccessFile.close();
  }
}
