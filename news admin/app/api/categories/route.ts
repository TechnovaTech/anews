import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import Category from '@/models/Category';
import { createCorsResponse, createCorsErrorResponse, handleOptionsRequest } from '@/lib/cors';

export async function GET() {
  try {
    await dbConnect();
    const categories = await Category.find().sort({ name: 1 });
    return createCorsResponse({ categories });
  } catch (error) {
    return createCorsErrorResponse('Failed to fetch categories', 500);
  }
}

export async function POST(req: NextRequest) {
  try {
    await dbConnect();
    const data = await req.json();
    console.log('Creating category with data:', data);
    const category = await Category.create(data);
    console.log('Created category:', category);
    return createCorsResponse({ category }, { status: 201 });
  } catch (error: any) {
    console.error('Error creating category:', error);
    return createCorsErrorResponse(error.message || 'Failed to create category', 500);
  }
}

export async function OPTIONS() {
  return handleOptionsRequest();
}
