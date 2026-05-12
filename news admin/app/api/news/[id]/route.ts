import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import News from '@/models/News';

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    await dbConnect();
    const { id } = await params;
    const news = await News.findById(id)
      .populate('category')
      .populate('tags');
    if (!news) {
      return NextResponse.json({ error: 'News not found' }, { status: 404 });
    }
    const newsObj = news.toObject();
    console.log('GET - Returning languages:', newsObj.languages);
    console.log('GET - Returning translations:', newsObj.translations);
    return NextResponse.json({ news: newsObj });
  } catch (error: any) {
    console.error('Error fetching news:', error);
    return NextResponse.json({ error: error.message || 'Failed to fetch news' }, { status: 500 });
  }
}

export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    await dbConnect();
    const { id } = await params;
    const data = await req.json();
    
    console.log('API - Received data:', JSON.stringify(data, null, 2));
    console.log('API - Languages:', data.languages);
    console.log('API - Translations:', data.translations);
    
    // Convert tag names to tag IDs
    let tagIds = [];
    if (data.tags && Array.isArray(data.tags)) {
      const Tag = (await import('@/models/Tag')).default;
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
    
    const db = (await import('mongoose')).default.connection.db;
    if (!db) throw new Error('Database connection not established');
    const result = await db.collection('news').updateOne(
      { _id: new (await import('mongoose')).default.Types.ObjectId(id) },
      {
        $set: {
          title: data.title,
          content: data.content,
          summary: data.summary,
          explanation: data.explanation,
          image: data.image,
          category: new (await import('mongoose')).default.Types.ObjectId(data.category),
          tags: tagIds,
          source: data.source,
          state: data.state,
          publishedAt: data.publishedAt,
          languages: data.languages,
          translations: data.translations,
          updatedAt: new Date()
        }
      }
    );
    console.log('Update result:', result);
    
    const news = await News.findById(id).populate('category').populate('tags');
    if (!news) {
      return NextResponse.json({ error: 'News not found' }, { status: 404 });
    }
    
    const newsObj = news.toObject();
    console.log('API - Saved news languages:', newsObj.languages);
    console.log('API - Saved news translations:', newsObj.translations);
    
    if (!news) {
      return NextResponse.json({ error: 'News not found' }, { status: 404 });
    }
    return NextResponse.json({ news });
  } catch (error: any) {
    console.error('Error updating news:', error);
    return NextResponse.json({ error: error.message || 'Failed to update news' }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    await dbConnect();
    const { id } = await params;
    await News.findByIdAndDelete(id);
    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error('Error deleting news:', error);
    return NextResponse.json({ error: error.message || 'Failed to delete news' }, { status: 500 });
  }
}
