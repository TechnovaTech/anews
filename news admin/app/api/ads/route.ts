import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import Advertisement from '@/models/Advertisement';

export async function GET(req: NextRequest) {
  try {
    await dbConnect();
    const { searchParams } = new URL(req.url);
    const status = searchParams.get('status');
    
    const query: any = {};
    if (status) query.status = status;

    const ads = await Advertisement.find(query).sort({ createdAt: -1 });
    return NextResponse.json({ ads });
  } catch (error: any) {
    console.error('Error fetching ads:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    await dbConnect();
    const data = await req.json();
    const ad = await Advertisement.create(data);
    return NextResponse.json({ ad }, { status: 201 });
  } catch (error: any) {
    console.error('Error creating ad:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
