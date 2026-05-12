import { NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import User from '@/models/User';

export async function PUT(req: Request, { params }: { params: Promise<{ id: string }> }) {
  await dbConnect();
  const { id } = await params;
  const { action, amount } = await req.json();
  
  console.log(`🔄 Adjusting wallet for user ${id}: ${action} ${amount}`);
  
  const user = await User.findById(id);
  if (!user) {
    return NextResponse.json({ error: 'User not found' }, { status: 404 });
  }
  
  const oldBalance = user.walletBalance || 0;
  
  if (action === 'increase') {
    user.walletBalance = oldBalance + amount;
  } else if (action === 'decrease') {
    user.walletBalance = Math.max(0, oldBalance - amount);
  }
  
  await user.save();
  
  console.log(`✅ Wallet updated: ${oldBalance} → ${user.walletBalance} (saved to DB)`);
  
  return NextResponse.json({ success: true, balance: user.walletBalance });
}
