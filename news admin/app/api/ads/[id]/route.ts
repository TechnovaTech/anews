import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import Advertisement from '@/models/Advertisement';

export async function PATCH(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    await dbConnect();
    const data = await req.json();
    const ad = await Advertisement.findByIdAndUpdate(id, data, { new: true });
    if (!ad) {
      return NextResponse.json({ error: 'Advertisement not found' }, { status: 404 });
    }
    return NextResponse.json({ ad });
  } catch (error: any) {
    console.error('Error updating ad:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    await dbConnect();
    const ad = await Advertisement.findByIdAndDelete(id);
    if (!ad) {
      return NextResponse.json({ error: 'Advertisement not found' }, { status: 404 });
    }
    return NextResponse.json({ message: 'Advertisement deleted successfully' });
  } catch (error: any) {
    console.error('Error deleting ad:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
