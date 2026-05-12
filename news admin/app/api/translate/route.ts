import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  let text = '';
  try {
    const body = await req.json();
    text = body.text;
    const targetLang = body.targetLang;

    if (!text || !targetLang || text.trim() === '') {
      return NextResponse.json({ translatedText: text || '' });
    }

    // Using Google Translate API (free tier)
    const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=${targetLang}&dt=t&q=${encodeURIComponent(text)}`;
    
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0'
      }
    });
    
    if (!response.ok) {
      console.error('Translation API error:', response.status);
      return NextResponse.json({ translatedText: text }, { status: 200 });
    }
    
    const data = await response.json();
    const translatedText = data[0]?.map((item: any) => item[0]).join('') || text;

    return NextResponse.json({ translatedText });
  } catch (error) {
    console.error('Translation error:', error);
    return NextResponse.json({ translatedText: text || '' }, { status: 200 });
  }
}
