'use client'

import { useState, useEffect } from 'react'
import Sidebar from '@/components/Sidebar'
import Link from 'next/link'

export default function StoriesListPage() {
  const [stories, setStories] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [viewStory, setViewStory] = useState<any>(null)
  const [showDetails, setShowDetails] = useState(false)
  const [liked, setLiked] = useState(false)

  useEffect(() => {
    fetchStories()
  }, [])

  const fetchStories = async () => {
    try {
      const res = await fetch('/api/stories')
      const data = await res.json()
      console.log('Stories data:', data.stories)
      setStories(data.stories || [])
    } catch (err) {
      console.error('Failed to fetch stories:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this story?')) return

    try {
      const res = await fetch(`/api/stories/${id}`, { method: 'DELETE' })
      if (res.ok) {
        alert('Story deleted successfully!')
        fetchStories()
      } else {
        alert('Failed to delete story')
      }
    } catch (err) {
      alert('Error deleting story')
    }
  }

  const toggleActive = async (id: string, currentStatus: boolean) => {
    try {
      const res = await fetch(`/api/stories/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ active: !currentStatus }),
      })
      if (res.ok) {
        fetchStories()
      }
    } catch (err) {
      alert('Error updating story')
    }
  }

  return (
    <div style={styles.container}>
      <Sidebar />
      <div style={styles.main}>
        <header style={styles.header}>
          <h1 style={styles.title}>Stories List</h1>
          <Link href="/stories/add" style={styles.addBtn}>+ Add New Story</Link>
        </header>

        <div style={styles.content}>
          {loading ? (
            <div style={styles.loading}>Loading...</div>
          ) : stories.length === 0 ? (
            <div style={styles.empty}>No stories found. Add your first story!</div>
          ) : (
            <div style={styles.grid}>
              {stories.map((story) => (
                <div key={story._id} style={styles.card}>
                  <div style={styles.imageContainer}>
                    {story.mediaItems && story.mediaItems.length > 0 ? (
                      story.mediaItems[0].type === 'video' ? (
                        <video src={story.mediaItems[0].url} style={styles.image} controls />
                      ) : (
                        <img src={story.mediaItems[0].url} alt={story.heading} style={styles.image} />
                      )
                    ) : story.videoUrl ? (
                      <video src={story.videoUrl} style={styles.image} controls />
                    ) : story.image ? (
                      <img src={story.image} alt={story.heading} style={styles.image} />
                    ) : (
                      <div style={styles.noMedia}>No Media</div>
                    )}
                    <button onClick={() => setViewStory(story)} style={styles.viewBtn}>
                      👁️
                    </button>
                  </div>
                  <div style={styles.cardContent}>
                    {(story.storyName || story.heading) && (
                      <div style={styles.storyName}>
                        {story.storyName || `Story: ${story.heading.substring(0, 20)}...`}
                      </div>
                    )}
                    <h3 style={styles.cardTitle}>{story.heading}</h3>
                    <p style={styles.description}>{story.description}</p>
                    <div style={styles.meta}>
                      <span style={styles.mediaType}>
                        {story.mediaItems && story.mediaItems.length > 0 
                          ? `${story.mediaItems.length} ${story.mediaItems.length === 1 ? 'Item' : 'Items'}`
                          : story.videoUrl ? 'Video' : 'Image'
                        }
                      </span>
                      <span style={{
                        ...styles.statusBadge,
                        backgroundColor: story.active ? '#4caf50' : '#f44336'
                      }}>
                        {story.active ? 'Active' : 'Inactive'}
                      </span>
                    </div>

                    <div style={styles.deleteInfo}>
                      <span style={styles.deleteLabel}>Auto Delete:</span>
                      <span style={styles.deleteTime}>
                        {story.autoDeleteType === 'hours' 
                          ? `In ${story.deleteAfterHours || 24} hours`
                          : story.autoDeleteType === 'days' && story.deleteAfterDate
                          ? `On ${new Date(story.deleteAfterDate).toLocaleDateString()}`
                          : 'Never'
                        }
                      </span>
                    </div>
                    <div style={styles.actions}>
                      <Link href={`/stories/edit/${story._id}`} style={styles.editBtn}>Edit</Link>
                      <button 
                        onClick={() => toggleActive(story._id, story.active)} 
                        style={{
                          ...styles.toggleBtn,
                          backgroundColor: story.active ? '#9e9e9e' : '#4caf50'
                        }}
                      >
                        {story.active ? 'Deactivate' : 'Activate'}
                      </button>
                      <button onClick={() => handleDelete(story._id)} style={styles.deleteBtn}>
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>


      </div>
    </div>
  )
}

const styles = {
  container: { display: 'flex', fontFamily: 'Arial, sans-serif' },
  main: { marginLeft: '250px', flex: 1, backgroundColor: '#f5f5f5', minHeight: '100vh' },
  header: {
    backgroundColor: 'white',
    padding: '20px 35px',
    borderBottom: '1px solid #e0e0e0',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  title: { color: '#e31e3a', fontSize: '24px', margin: 0, fontWeight: 600 },
  addBtn: {
    backgroundColor: '#e31e3a',
    color: 'white',
    padding: '10px 20px',
    borderRadius: '5px',
    textDecoration: 'none',
    fontSize: '14px',
    fontWeight: 600,
  },
  content: { padding: '35px' },
  loading: { textAlign: 'center' as const, padding: '50px', fontSize: '16px' },
  empty: { textAlign: 'center' as const, padding: '50px', fontSize: '16px', color: '#666' },
  grid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '25px' },
  card: { backgroundColor: 'white', borderRadius: '12px', overflow: 'hidden', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' },
  imageContainer: { position: 'relative' as const },
  image: { width: '100%', height: '200px', objectFit: 'cover' as const },
  noMedia: { 
    width: '100%', 
    height: '200px', 
    backgroundColor: '#f0f0f0', 
    display: 'flex', 
    alignItems: 'center', 
    justifyContent: 'center',
    color: '#666'
  },
  viewBtn: {
    position: 'absolute' as const,
    top: '12px',
    right: '12px',
    backgroundColor: 'rgba(0,0,0,0.7)',
    border: 'none',
    borderRadius: '50%',
    width: '40px',
    height: '40px',
    fontSize: '18px',
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
  cardContent: { padding: '20px' },
  storyName: { 
    fontSize: '12px', 
    fontWeight: 600, 
    color: '#e31e3a', 
    backgroundColor: '#fff5f5', 
    padding: '4px 8px', 
    borderRadius: '4px', 
    marginBottom: '8px',
    display: 'inline-block'
  },
  cardTitle: { fontSize: '18px', fontWeight: 700, marginBottom: '8px', color: '#333' },
  description: { 
    fontSize: '14px', 
    color: '#666', 
    marginBottom: '15px', 
    lineHeight: '1.5',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap'
  },
  meta: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '15px' },
  mediaType: { fontSize: '12px', color: '#666', backgroundColor: '#f5f5f5', padding: '4px 8px', borderRadius: '12px' },
  deleteInfo: { 
    display: 'flex', 
    alignItems: 'center', 
    gap: '8px', 
    marginBottom: '15px',
    padding: '8px 12px',
    backgroundColor: '#fff3cd',
    borderRadius: '6px',
    border: '1px solid #ffeaa7'
  },
  deleteLabel: { fontSize: '11px', fontWeight: 600, color: '#856404' },
  deleteTime: { fontSize: '11px', color: '#856404', fontWeight: 500 },
  statusBadge: { fontSize: '11px', color: 'white', padding: '4px 10px', borderRadius: '12px', fontWeight: 600 },
  actions: { display: 'flex', gap: '8px' },
  editBtn: {
    flex: 1,
    padding: '10px 16px',
    backgroundColor: '#ff9800',
    color: 'white',
    textDecoration: 'none',
    textAlign: 'center' as const,
    borderRadius: '6px',
    fontSize: '13px',
    fontWeight: 600,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
  toggleBtn: {
    flex: 1,
    padding: '10px 16px',
    border: 'none',
    borderRadius: '6px',
    color: 'white',
    fontSize: '13px',
    fontWeight: 600,
    cursor: 'pointer',
  },
  deleteBtn: {
    flex: 1,
    padding: '10px 16px',
    backgroundColor: '#f44336',
    border: 'none',
    borderRadius: '6px',
    color: 'white',
    fontSize: '13px',
    fontWeight: 600,
    cursor: 'pointer',
  },
  modal: {
    position: 'fixed' as const,
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0,0,0,0.8)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 1000,
  },
  modalContent: { position: 'relative' as const },
  closeBtn: {
    position: 'absolute' as const,
    top: '-40px',
    right: '0',
    background: 'white',
    border: 'none',
    fontSize: '30px',
    width: '35px',
    height: '35px',
    borderRadius: '50%',
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    lineHeight: '1',
  },
  phoneFrame: {
    width: '300px',
    height: '600px',
    backgroundColor: '#000',
    borderRadius: '30px',
    overflow: 'hidden',
    position: 'relative' as const,
    boxShadow: '0 10px 40px rgba(0,0,0,0.5)',
  },
  previewMedia: { width: '100%', height: '100%', objectFit: 'cover' as const },
  placeholderMedia: {
    width: '100%',
    height: '100%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    color: '#666',
    fontSize: '14px',
    backgroundColor: '#f0f0f0',
  },
  storyOverlay: {
    position: 'absolute' as const,
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    background: 'linear-gradient(to bottom, rgba(0,0,0,0.3) 0%, transparent 30%, transparent 60%, rgba(0,0,0,0.5) 100%)',
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'space-between',
    padding: '20px',
    pointerEvents: 'none',
  },
  storyHeader: { display: 'flex', justifyContent: 'center' },
  storyBrand: { color: 'white', fontSize: '18px', fontWeight: 700, letterSpacing: '1px' },
  readDetailBtn: {
    position: 'absolute' as const,
    bottom: '20px',
    left: '20px',
    backgroundColor: 'rgba(255,255,255,0.2)',
    color: 'white',
    border: '1px solid rgba(255,255,255,0.5)',
    padding: '10px 20px',
    borderRadius: '20px',
    fontSize: '13px',
    fontWeight: 600,
    cursor: 'pointer',
    pointerEvents: 'auto',
  },
  actionButtons: {
    position: 'absolute' as const,
    bottom: '20px',
    right: '20px',
    display: 'flex',
    gap: '10px',
    pointerEvents: 'auto',
  },
  actionBtn: {
    backgroundColor: 'transparent',
    border: 'none',
    color: 'white',
    fontSize: '28px',
    cursor: 'pointer',
    padding: '5px',
  },
  detailsPanel: {
    position: 'absolute' as const,
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: 'rgba(255,255,255,0.15)',
    borderTopLeftRadius: '20px',
    borderTopRightRadius: '20px',
    padding: '25px 20px',
    maxHeight: '70%',
    overflowY: 'auto',
  },
  closeDetailsBtn: {
    position: 'absolute' as const,
    top: '10px',
    right: '10px',
    background: 'transparent',
    border: 'none',
    fontSize: '24px',
    cursor: 'pointer',
    color: 'white',
  },
  detailHeading: { fontSize: '18px', fontWeight: 700, marginBottom: '12px', color: 'white', marginTop: '10px' },
  detailDescription: { fontSize: '14px', lineHeight: '1.6', color: 'white' },
}