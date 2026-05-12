import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/mongodb';
import Notification from '@/models/Notification';
import User from '@/models/User';

export async function POST(req: NextRequest) {
  try {
    await dbConnect();
    const data = await req.json();
    
    const { contentId, contentType, translations, link, audience, sendNow, scheduleDate } = data;

    // Create notification record
    const notification = await Notification.create({
      contentId,
      contentType,
      translations,
      link,
      audience,
      status: sendNow ? 'sent' : 'scheduled',
      scheduledFor: scheduleDate,
      sentAt: sendNow ? new Date() : null
    });

    // If sending now, send to users based on their language preference
    if (sendNow) {
      const query: any = {};
      
      // Filter by language if specified
      if (audience.languages && audience.languages.length > 0) {
        query.language = { $in: audience.languages };
      }

      const users = await User.find(query).select('_id language');
      
      // In a real app, you would send push notifications here
      // For now, we'll just log the notification data
      console.log(`Sending notifications to ${users.length} users`);
      
      users.forEach(user => {
        const userLang = user.language || 'EN';
        let title = '';
        let message = '';
        
        // Select appropriate translation based on user language
        if (userLang === 'HIN' && translations.hindi) {
          title = translations.hindi.title;
          message = translations.hindi.message;
        } else if (userLang === 'BEN' && translations.bengali) {
          title = translations.bengali.title;
          message = translations.bengali.message;
        } else {
          title = translations.english.title;
          message = translations.english.message;
        }
        
        console.log(`User ${user._id} (${userLang}): ${title}`);
        
        // Here you would integrate with Firebase Cloud Messaging or similar service
        // to send actual push notifications to mobile devices
      });
    }

    return NextResponse.json({ 
      success: true, 
      notification,
      message: `Notification ${sendNow ? 'sent' : 'scheduled'} successfully`
    });
  } catch (error: any) {
    console.error('Error sending notification:', error);
    return NextResponse.json({ 
      success: false,
      message: error.message || 'Failed to send notification' 
    }, { status: 500 });
  }
}
