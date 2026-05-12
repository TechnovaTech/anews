import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import Notification from '@/models/Notification';

export async function GET(req: NextRequest) {
  try {
    await dbConnect();
    const { searchParams } = new URL(req.url);
    const language = searchParams.get('language') || 'EN';
    
    // Fetch recent notifications
    const notifications = await Notification.find({ status: 'sent' })
      .sort({ sentAt: -1 })
      .limit(50)
      .lean();

    // Map notifications to user's language
    const mappedNotifications = notifications.map(notif => {
      let title = '';
      let message = '';
      
      // Select appropriate translation based on language
      if (language === 'HIN' && notif.translations?.hindi) {
        title = notif.translations.hindi.title;
        message = notif.translations.hindi.message;
      } else if (language === 'BEN' && notif.translations?.bengali) {
        title = notif.translations.bengali.title;
        message = notif.translations.bengali.message;
      } else {
        title = notif.translations?.english?.title || '';
        message = notif.translations?.english?.message || '';
      }

      return {
        _id: notif._id,
        title,
        message,
        contentType: notif.contentType,
        contentId: notif.contentId,
        link: notif.link,
        sentAt: notif.sentAt,
        createdAt: notif.createdAt
      };
    });

    return NextResponse.json({ notifications: mappedNotifications });
  } catch (error: any) {
    console.error('Error fetching notifications:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
