import { NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import Reward from '@/models/Reward';

export async function GET() {
  await dbConnect();
  const rewards = await Reward.find().sort({ createdAt: -1 });
  return NextResponse.json({ rewards });
}

export async function POST(req: Request) {
  await dbConnect();
  const body = await req.json();
  console.log('Creating reward with data:', body);
  const reward = await Reward.create(body);
  console.log('Created reward:', reward);
  return NextResponse.json(reward, { status: 201 });
}
