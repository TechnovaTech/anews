import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import Reel from '@/models/Reel';
import { createCorsResponse, createCorsErrorResponse, handleOptionsRequest } from '@/lib/cors';

export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    await dbConnect();
    const reel = await Reel.findByIdAndUpdate(id, { $inc: { saves: 1 } }, { new: true });
    if (!reel) return createCorsErrorResponse('Reel not found', 404);
    return createCorsResponse({ saves: reel.saves });
  } catch (error) {
    return createCorsErrorResponse('Failed to save reel', 500);
  }
}

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    await dbConnect();
    const reel = await Reel.findByIdAndUpdate(id, { $inc: { saves: -1 } }, { new: true });
    if (!reel) return createCorsErrorResponse('Reel not found', 404);
    return createCorsResponse({ saves: Math.max(0, reel.saves) });
  } catch (error) {
    return createCorsErrorResponse('Failed to unsave reel', 500);
  }
}

export async function OPTIONS() {
  return handleOptionsRequest();
}
