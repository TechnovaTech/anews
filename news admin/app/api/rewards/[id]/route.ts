import { NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import Reward from '@/models/Reward';

export async function PUT(req: Request, { params }: { params: Promise<{ id: string }> }) {
  await dbConnect();
  const { id } = await params;
  const body = await req.json();
  console.log('Updating reward with data:', body);
  const reward = await Reward.findByIdAndUpdate(id, body, { new: true });
  console.log('Updated reward:', reward);
  if (!reward) {
    return NextResponse.json({ error: 'Reward not found' }, { status: 404 });
  }
  return NextResponse.json(reward);
}

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  await dbConnect();
  const { id } = await params;
  const reward = await Reward.findByIdAndDelete(id);
  if (!reward) {
    return NextResponse.json({ error: 'Reward not found' }, { status: 404 });
  }
  return NextResponse.json({ success: true });
}
