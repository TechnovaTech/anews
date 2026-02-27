import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import News from '@/models/News';
import Tag from '@/models/Tag';
import Category from '@/models/Category';
import { createCorsResponse, createCorsErrorResponse, handleOptionsRequest } from '@/lib/cors';

export async function GET(req: NextRequest) {
  try {
    await dbConnect();
    
    const { searchParams } = new URL(req.url);
    const status = searchParams.get('status');
    const category = searchParams.get('category');
    const language = searchParams.get('language');
    const userState = searchParams.get('userState');
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '20');
    
    const query: any = {};
    if (status && status !== 'all') {
      query.status = status;
    } else if (!status) {
      query.status = 'published';
    }
    if (category && category !== 'story') query.category = category;
    if (language) query.languages = language;
    if (userState && userState !== '') {
      query.$or = [{ state: userState }, { state: { $in: [null, ''] } }];
    }

    const skip = (page - 1) * limit;
    const [news, total] = await Promise.all([
      News.find(query)
        .populate('category')
        .populate('tags')
        .lean()
        .sort({ publishedAt: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit),
      News.countDocuments(query)
    ]);

    const baseUrl = process.env.BASE_URL || 'https://asiaze.cloud';
    const newsWithFullUrls = news.map(item => ({
      ...item,
      image: item.image && (item.image.startsWith('http') || item.image.startsWith('data:')) 
        ? item.image 
        : item.image ? `${baseUrl}${item.image}` : ''
    }));

    return createCorsResponse({ 
      news: newsWithFullUrls,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error: any) {
    console.error('Error fetching news:', error);
    return createCorsErrorResponse(error.message || 'Failed to fetch news', 500);
  }
}

export async function POST(req: NextRequest) {
  try {
    await dbConnect();
    const data = await req.json();
    
    if (!data.title || !data.category) {
      return createCorsErrorResponse('Title and category are required', 400);
    }

    if (data.languages && !Array.isArray(data.languages)) {
      return createCorsErrorResponse('Languages must be an array', 400);
    }

    let tagIds = [];
    if (data.tags && Array.isArray(data.tags)) {
      try {
        tagIds = await Promise.all(
          data.tags.map(async (tagName: string) => {
            try {
              let tag = await Tag.findOne({ name: tagName });
              if (!tag) {
                tag = await Tag.create({ 
                  name: tagName, 
                  slug: tagName.toLowerCase().replace(/\s+/g, '-'),
                  isActive: true 
                });
              }
              return tag._id;
            } catch (err) {
              console.error(`Error processing tag "${tagName}":`, err);
              throw new Error(`Failed to process tag: ${tagName}`);
            }
          })
        );
      } catch (err: any) {
        return createCorsErrorResponse(err.message || 'Failed to process tags', 400);
      }
    }

    const newsData = {
      title: data.title,
      content: data.content || '',
      summary: data.summary || '',
      explanation: data.explanation || '',
      image: data.image || '',
      videoUrl: data.videoUrl || '',
      category: data.category,
      tags: tagIds,
      status: data.status || 'draft',
      languages: data.languages || [],
      translations: data.translations || {},
      source: data.source || '',
      state: data.state || '',
      publishedAt: data.publishedAt || null
    };
    
    const news = new News(newsData);
    news.markModified('translations');
    await news.save();

    return createCorsResponse({ news }, { status: 201 });
  } catch (error: any) {
    console.error('Error creating news:', error);
    return createCorsErrorResponse(error.message || 'Failed to create news', 500);
  }
}

export async function OPTIONS() {
  return handleOptionsRequest();
}
