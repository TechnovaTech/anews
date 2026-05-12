import { NextRequest, NextResponse } from 'next/server';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import dbConnect from '@/lib/mongodb';
import User from '@/models/User';
import { createCorsResponse, createCorsErrorResponse, handleOptionsRequest } from '@/lib/cors';

export async function POST(req: NextRequest) {
  try {
    await dbConnect();
    const { email, password } = await req.json();

    if (!email || !password) {
      return createCorsErrorResponse('Email and password required', 400);
    }

    const user = await User.findOne({ email });
    if (!user) {
      return createCorsErrorResponse('Invalid credentials', 401);
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return createCorsErrorResponse('Invalid credentials', 401);
    }

    const token = jwt.sign(
      { userId: user._id, email: user.email },
      process.env.JWT_SECRET || 'fallback-secret',
      { expiresIn: '30d' }
    );

    return createCorsResponse({
      user: { 
        _id: user._id, 
        name: user.name, 
        email: user.email, 
        state: user.state,
        walletBalance: user.walletBalance || 0
      },
      token
    });
  } catch (error) {
    console.error('User login error:', error);
    return createCorsErrorResponse('Login failed', 500);
  }
}

export async function OPTIONS() {
  return handleOptionsRequest();
}