import { NextRequest, NextResponse } from 'next/server';
import bcrypt from 'bcryptjs';
import dbConnect from '@/lib/mongodb';
import User from '@/models/User';
import { createCorsResponse, createCorsErrorResponse, handleOptionsRequest } from '@/lib/cors';

export async function GET() {
  try {
    await dbConnect();
    const users = await User.find().select('-password').sort({ createdAt: -1 });
    return createCorsResponse({ users });
  } catch (error) {
    return createCorsErrorResponse('Failed to fetch users', 500);
  }
}

export async function POST(req: NextRequest) {
  try {
    await dbConnect();
    const data = await req.json();
    
    const hashedPassword = await bcrypt.hash(data.password, 10);
    const user = await User.create({
      ...data,
      password: hashedPassword
    });

    const { password, ...userWithoutPassword } = user.toObject();
    return createCorsResponse({ user: userWithoutPassword }, { status: 201 });
  } catch (error) {
    return createCorsErrorResponse('Failed to create user', 500);
  }
}

export async function OPTIONS() {
  return handleOptionsRequest();
}
