import { NextRequest, NextResponse } from 'next/server';
import bcrypt from 'bcryptjs';
import dbConnect from '@/lib/mongodb';
import User from '@/models/User';
import { createCorsResponse, createCorsErrorResponse, handleOptionsRequest } from '@/lib/cors';

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    await dbConnect();
    const { id } = await params;
    const user = await User.findById(id).select('-password');

    if (!user) {
      return createCorsErrorResponse('User not found', 404);
    }

    return createCorsResponse({ user });
  } catch (error) {
    return createCorsErrorResponse('Failed to fetch user', 500);
  }
}

export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    await dbConnect();
    const { id } = await params;
    const data = await req.json();
    
    if (data.password) {
      data.password = await bcrypt.hash(data.password, 10);
    }

    const user = await User.findByIdAndUpdate(id, data, { new: true }).select('-password');

    if (!user) {
      return createCorsErrorResponse('User not found', 404);
    }

    return createCorsResponse({ user });
  } catch (error) {
    return createCorsErrorResponse('Failed to update user', 500);
  }
}

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    await dbConnect();
    const { id } = await params;
    const user = await User.findByIdAndDelete(id);

    if (!user) {
      return createCorsErrorResponse('User not found', 404);
    }

    return createCorsResponse({ message: 'User deleted successfully' });
  } catch (error) {
    return createCorsErrorResponse('Failed to delete user', 500);
  }
}

export async function OPTIONS() {
  return handleOptionsRequest();
}
