import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import Reel from '@/models/Reel';

export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    await dbConnect();
    
    const reel = await Reel.findByIdAndUpdate(
      id,
      { $inc: { likes: 1 } },
      { new: true }
    );

    if (!reel) {
      return NextResponse.json({ error: 'Reel not found' }, { status: 404 });
    }

    return NextResponse.json({ likes: reel.likes });
  } catch (error) {
    console.error('Like reel error:', error);
    return NextResponse.json({ error: 'Failed to like reel' }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    await dbConnect();
    
    const reel = await Reel.findByIdAndUpdate(
      id,
      { $inc: { likes: -1 } },
      { new: true }
    );

    if (!reel) {
      return NextResponse.json({ error: 'Reel not found' }, { status: 404 });
    }

    return NextResponse.json({ likes: Math.max(0, reel.likes) });
  } catch (error) {
    console.error('Unlike reel error:', error);
    return NextResponse.json({ error: 'Failed to unlike reel' }, { status: 500 });
  }
}
