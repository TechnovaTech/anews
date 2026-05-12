import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import User from '@/models/User';
import { createCorsResponse, createCorsErrorResponse, handleOptionsRequest } from '@/lib/cors';

export async function POST(req: NextRequest) {
  try {
    await dbConnect();
    const { email, name, googleId, state } = await req.json();

    if (!email || !name || !googleId) {
      return createCorsErrorResponse('Email, name, and Google ID required', 400);
    }

    // Check if user already exists
    let user = await User.findOne({ email });
    let isNew = false;
    
    if (user) {
      // Update existing user with Google ID if not set
      if (!user.googleId) {
        user.googleId = googleId;
        await user.save();
      }
    } else {
      // Create new user
      user = await User.create({
        name,
        email,
        googleId,
        state: state || '',
        password: 'google_auth',
        role: 'user',
        isActive: true,
      });
      isNew = true;
    }

    return createCorsResponse({
      isNew,
      user: { 
        _id: user._id, 
        name: user.name, 
        email: user.email, 
        state: user.state,
        walletBalance: user.walletBalance || 0
      }
    }, { status: isNew ? 201 : 200 });
  } catch (error) {
    console.error('Google login error:', error);
    return createCorsErrorResponse('Google login failed', 500);
  }
}

export async function OPTIONS() {
  return handleOptionsRequest();
}