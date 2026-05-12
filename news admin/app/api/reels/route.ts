import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import Reel from '@/models/Reel';
import Tag from '@/models/Tag';
import Category from '@/models/Category';
import { createCorsResponse, createCorsErrorResponse, handleOptionsRequest } from '@/lib/cors';

export async function GET(req: NextRequest) {
  try {
    await dbConnect();
    Category;
    const { searchParams } = new URL(req.url);
    const status = searchParams.get('status');
    const category = searchParams.get('category');
    const language = searchParams.get('language');
    
    const query: any = {};
    if (status && status !== 'all') {
      query.status = status;
    } else if (!status) {
      query.status = 'published';
    }
    if (category) query.category = category;
    if (language) query.language = language;

    console.log('Reels query:', query);
    const reels = await Reel.find(query)
      .populate('category', 'name')
      .lean()
      .sort({ createdAt: -1 });
    
    // Convert relative URLs to absolute URLs
    const baseUrl = process.env.BASE_URL || 'https://asiaze.cloud';
    const reelsWithFullUrls = reels.map(reel => ({
      ...reel,
      videoUrl: reel.videoUrl?.startsWith('http') ? reel.videoUrl : `${baseUrl}${reel.videoUrl}`,
      thumbnail: reel.thumbnail?.startsWith('http') ? reel.thumbnail : (reel.thumbnail?.startsWith('data:') ? reel.thumbnail : `${baseUrl}${reel.thumbnail}`)
    }));
    
    console.log(`Found ${reels.length} reels`);
    return createCorsResponse({ reels: reelsWithFullUrls });
  } catch (error: any) {
    console.error('Error fetching reels:', error);
    return createCorsErrorResponse(error.message || 'Failed to fetch reels', 500);
  }
}

export async function POST(req: NextRequest) {
  try {
    await dbConnect();
    const data = await req.json();
    
    let tagIds = [];
    if (data.tags && Array.isArray(data.tags)) {
      tagIds = await Promise.all(
        data.tags.map(async (tagName: string) => {
          let tag = await Tag.findOne({ name: tagName });
          if (!tag) {
            tag = await Tag.create({ 
              name: tagName, 
              slug: tagName.toLowerCase().replace(/\s+/g, '-'),
              isActive: true 
            });
          }
          return tag._id;
        })
      );
    }
    
    const reel = await Reel.create({
      ...data,
      tags: tagIds,
      updatedAt: new Date()
    });

    return createCorsResponse({ reel }, { status: 201 });
  } catch (error: any) {
    console.error('Error creating reel:', error);
    return createCorsErrorResponse(error.message || 'Failed to create reel', 500);
  }
}

export async function OPTIONS() {
  return handleOptionsRequest();
}
