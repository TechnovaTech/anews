import { NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import Story from '@/models/Story';

export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  await dbConnect();
  const { id } = await params;
  const story = await Story.findById(id);
  if (!story) return NextResponse.json({ error: 'Story not found' }, { status: 404 });
  return NextResponse.json({ story });
}

export async function PUT(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await dbConnect();
    const { id } = await params;
    const body = await req.json();
    console.log('Updating story with data:', body);
    
    const story = await Story.findByIdAndUpdate(id, body, { new: true, strict: false });
    console.log('Updated story:', story);
    if (!story) return NextResponse.json({ error: 'Story not found' }, { status: 404 });
    return NextResponse.json({ story });
  } catch (error: any) {
    console.error('Error updating story:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  await dbConnect();
  const { id } = await params;
  const story = await Story.findByIdAndDelete(id);
  if (!story) return NextResponse.json({ error: 'Story not found' }, { status: 404 });
  return NextResponse.json({ success: true });
}
