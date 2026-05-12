import { NextRequest, NextResponse } from 'next/server';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import dbConnect from '@/lib/mongodb';
import AdminUser from '@/models/AdminUser';
import { createCorsResponse, createCorsErrorResponse, handleOptionsRequest, corsHeaders } from '@/lib/cors';

export async function POST(req: NextRequest) {
  try {
    await dbConnect();
    const { email, password } = await req.json();

    if (!email || !password) {
      return createCorsErrorResponse('Email and password required', 400);
    }

    const user = await AdminUser.findOne({ email });
    if (!user) {
      return createCorsErrorResponse('Invalid credentials', 401);
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return createCorsErrorResponse('Invalid credentials', 401);
    }

    if (user.status !== 'Active') {
      return createCorsErrorResponse('Account is inactive', 403);
    }

    const token = jwt.sign(
      { userId: user._id, email: user.email, role: user.roleName, modules: user.modules },
      process.env.JWT_SECRET!,
      { expiresIn: '7d' }
    );

    const response = NextResponse.json({
      user: { id: user._id, name: user.name, email: user.email, role: user.roleName, modules: user.modules }
    }, {
      headers: corsHeaders()
    });

    response.cookies.set('token', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 7
    });

    return response;
  } catch (error) {
    return createCorsErrorResponse('Login failed', 500);
  }
}

export async function OPTIONS() {
  return handleOptionsRequest();
}
