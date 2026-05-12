import { NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import Tag from '@/models/Tag';

export async function GET() {
  await dbConnect();
  const tags = await Tag.find().sort({ createdAt: -1 });
  return NextResponse.json(tags);
}

export async function POST(request: Request) {
  await dbConnect();
  const body = await request.json();
  const slug = body.name.toLowerCase().replace(/\s+/g, '-');
  const tag = await Tag.create({ ...body, slug });
  return NextResponse.json(tag);
}
