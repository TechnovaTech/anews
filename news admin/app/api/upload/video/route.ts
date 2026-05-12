import { NextRequest, NextResponse } from 'next/server';
import { appendFile, writeFile } from 'fs/promises';
import { join } from 'path';
import { existsSync } from 'fs';

export const maxDuration = 300;

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    console.log('Received chunk:', body.chunkIndex, 'of', body.totalChunks);
    
    const { chunkData, filename, chunkIndex, totalChunks } = body;

    if (!chunkData || !filename) {
      console.error('Missing data:', { hasChunkData: !!chunkData, hasFilename: !!filename });
      return NextResponse.json({ error: 'No data' }, { status: 400 });
    }

    const base64Data = chunkData.includes(',') ? chunkData.split(',')[1] : chunkData;
    const buffer = Buffer.from(base64Data, 'base64');
    
    const filepath = join(process.cwd(), 'public', 'uploads', 'videos', filename);
    console.log('Writing to:', filepath, 'Size:', buffer.length);
    
    if (chunkIndex === 0) {
      await writeFile(filepath, buffer);
    } else {
      await appendFile(filepath, buffer);
    }

    console.log('Chunk saved successfully');
    return NextResponse.json({ 
      success: true,
      chunkIndex,
      totalChunks
    });

  } catch (error: any) {
    console.error('Video upload error:', error);
    console.error('Error stack:', error.stack);
    return NextResponse.json({ error: error.message, stack: error.stack }, { status: 500 });
  }
}
