import { NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import Tag from '@/models/Tag';

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  await dbConnect();
  const body = await request.json();
  if (body.name) {
    body.slug = body.name.toLowerCase().replace(/\s+/g, '-');
  }
  body.updatedAt = new Date();
  const tag = await Tag.findByIdAndUpdate(id, body, { new: true });
  return NextResponse.json(tag);
}

export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  await dbConnect();
  await Tag.findByIdAndDelete(id);
  return NextResponse.json({ success: true });
}
