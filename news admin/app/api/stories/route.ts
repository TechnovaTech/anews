import { NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import Story from '@/models/Story';

export async function GET() {
  await dbConnect();
  const stories = await Story.find().sort({ createdAt: -1 });
  
  // Convert relative URLs to absolute URLs
  const baseUrl = process.env.BASE_URL || 'https://asiaze.cloud';
  const storiesWithFullUrls = stories.map(story => ({
    ...story.toObject(),
    mediaItems: story.mediaItems?.map((item: any) => ({
      ...item,
      url: item.url?.startsWith('http') ? item.url : `${baseUrl}${item.url}`,
      thumbnail: item.thumbnail?.startsWith('http') ? item.thumbnail : (item.thumbnail ? `${baseUrl}${item.thumbnail}` : undefined)
    }))
  }));
  
  return NextResponse.json({ stories: storiesWithFullUrls });
}

export async function POST(req: Request) {
  await dbConnect();
  const body = await req.json();
  console.log('Received story data:', body);
  const story = await Story.create(body);
  console.log('Created story:', story);
  return NextResponse.json({ story }, { status: 201 });
}
