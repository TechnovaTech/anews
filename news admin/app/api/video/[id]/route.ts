import { NextRequest, NextResponse } from 'next/server';
import { MongoClient, GridFSBucket, ObjectId } from 'mongodb';

const uri = process.env.MONGODB_URI || '';

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  let client: MongoClient | null = null;
  
  try {
    const { id } = await params;
    
    client = await MongoClient.connect(uri);
    const db = client.db();
    const bucket = new GridFSBucket(db, { bucketName: 'videos' });

    const downloadStream = bucket.openDownloadStream(new ObjectId(id));
    
    const chunks: Buffer[] = [];
    for await (const chunk of downloadStream) {
      chunks.push(chunk);
    }
    
    const buffer = Buffer.concat(chunks);
    
    return new NextResponse(buffer, {
      headers: {
        'Content-Type': 'video/mp4',
        'Content-Length': buffer.length.toString(),
      },
    });

  } catch (error: any) {
    console.error('Video stream error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  } finally {
    if (client) await client.close();
  }
}
