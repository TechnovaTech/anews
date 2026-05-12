import { NextRequest, NextResponse } from 'next/server';
import { readFile } from 'fs/promises';
import { join } from 'path';

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  try {
    const { path } = await params;
    const filePath = join(process.cwd(), 'public', 'uploads', 'videos', ...path);
    
    const file = await readFile(filePath);
    
    return new NextResponse(new Uint8Array(file), {
      headers: {
        'Content-Type': 'video/mp4',
        'Accept-Ranges': 'bytes',
        'Access-Control-Allow-Origin': '*',
      },
    });
  } catch (error) {
    console.error('Video serve error:', error);
    return NextResponse.json({ error: 'Video not found' }, { status: 404 });
  }
}
