import { NextRequest, NextResponse } from 'next/server';
import { appendFile, writeFile } from 'fs/promises';
import { join } from 'path';
import { mkdir } from 'fs/promises';

export const maxDuration = 300;

export async function POST(req: NextRequest) {
  try {
    const contentType = req.headers.get('content-type') || '';

    // Ensure upload directory exists
    const uploadDir = join(process.cwd(), 'public', 'uploads', 'videos');
    await mkdir(uploadDir, { recursive: true });

    // ── FormData upload (from story page) ──────────────────────────
    if (contentType.includes('multipart/form-data')) {
      const formData = await req.formData();
      const file = formData.get('video') as File;

      if (!file) {
        return NextResponse.json({ error: 'No video file provided' }, { status: 400 });
      }

      const filename = `${Date.now()}-${file.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
      const filepath = join(uploadDir, filename);
      const bytes = await file.arrayBuffer();
      await writeFile(filepath, Buffer.from(bytes));

      console.log('Video uploaded via FormData:', filename);
      return NextResponse.json({
        success: true,
        videoUrl: `/uploads/videos/${filename}`,
        thumbnail: '',
      });
    }

    // ── Chunked base64 JSON upload (from news/reels add page) ──────
    const rawText = await req.text();
    let body: any;
    try {
      body = JSON.parse(rawText);
    } catch (parseError) {
      console.error('JSON parse error, raw length:', rawText.length);
      return NextResponse.json({ error: 'Invalid request format' }, { status: 400 });
    }

    console.log('Received chunk:', body.chunkIndex, 'of', body.totalChunks);
    const { chunkData, filename, chunkIndex, totalChunks } = body;

    if (!chunkData || !filename) {
      return NextResponse.json({ error: 'No data' }, { status: 400 });
    }

    let base64Data = chunkData.includes(',') ? chunkData.split(',')[1] : chunkData;
    base64Data = base64Data.replace(/ /g, '+');
    const buffer = Buffer.from(base64Data, 'base64');

    const filepath = join(uploadDir, filename);
    console.log('Writing chunk to:', filepath, 'Size:', buffer.length);

    if (chunkIndex === 0) {
      await writeFile(filepath, buffer);
    } else {
      await appendFile(filepath, buffer);
    }

    console.log('Chunk saved successfully');
    return NextResponse.json({ success: true, chunkIndex, totalChunks });

  } catch (error: any) {
    console.error('Video upload error:', error.message);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
