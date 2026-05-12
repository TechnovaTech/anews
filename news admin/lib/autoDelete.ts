import dbConnect from './mongodb';
import Story from '@/models/Story';

export async function checkAutoDelete() {
  await dbConnect();
  const now = new Date();
  
  // Find stories to auto-delete
  const storiesToDelete = await Story.find({
    $or: [
      {
        autoDeleteType: 'hours',
        createdAt: { $lte: new Date(now.getTime() - (24 * 60 * 60 * 1000)) }
      },
      {
        autoDeleteType: 'days',
        deleteAfterDate: { $lte: now.toISOString().split('T')[0] }
      }
    ]
  });

  // Delete expired stories
  for (const story of storiesToDelete) {
    const shouldDelete = 
      (story.autoDeleteType === 'hours' && 
       story.deleteAfterHours && 
       now.getTime() - story.createdAt.getTime() >= story.deleteAfterHours * 60 * 60 * 1000) ||
      (story.autoDeleteType === 'days' && 
       story.deleteAfterDate && 
       now >= new Date(story.deleteAfterDate));

    if (shouldDelete) {
      await Story.findByIdAndDelete(story._id);
    }
  }
}