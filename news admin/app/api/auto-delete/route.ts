import { NextResponse } from 'next/server';
import { checkAutoDelete } from '@/lib/autoDelete';

export async function GET() {
  try {
    await checkAutoDelete();
    return NextResponse.json({ success: true });
  } catch (error) {
    return NextResponse.json({ error: 'Auto-delete failed' }, { status: 500 });
  }
}