import { NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import PointSettings from '@/models/PointSettings';

export async function GET() {
  await dbConnect();
  let settings = await PointSettings.findOne();
  if (!settings) {
    settings = await PointSettings.create({});
  }
  return NextResponse.json(settings);
}

export async function PUT(req: Request) {
  await dbConnect();
  const body = await req.json();
  let settings = await PointSettings.findOne();
  if (!settings) {
    settings = await PointSettings.create(body);
  } else {
    settings = await PointSettings.findOneAndUpdate({}, body, { new: true });
  }
  return NextResponse.json(settings);
}
