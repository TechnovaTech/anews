import { NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import User from '@/models/User';

export async function GET() {
  await dbConnect();
  
  const users = await User.find({ role: 'user' }).select('name email walletBalance');
  
  return NextResponse.json({
    users: users.map(u => ({
      id: u._id,
      userId: u._id,
      userName: u.name,
      email: u.email,
      balance: u.walletBalance || 0,
      transactions: 0
    })),
    stats: { totalSavePoints: 0, totalSharePoints: 0, totalReferralPoints: 0, totalReferrals: 0 }
  });
}
