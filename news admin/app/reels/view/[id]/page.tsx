'use client'

import React, { useState, useEffect, use } from 'react'
import { useRouter } from 'next/navigation'
import Sidebar from '@/components/Sidebar'
import styles from './page.module.css'

export default function ViewReelPage({ params }: { params: Promise<{ id: string }> }) {
  const { id: reelId } = use(params)
  const router = useRouter()
  const [reel, setReel] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [currentTime, setCurrentTime] = useState(0)
  const [duration, setDuration] = useState(0)
  const [isMuted, setIsMuted] = useState(true)
  const [isLiked, setIsLiked] = useState(false)
  const [isSaved, setIsSaved] = useState(false)
  const [isDragging, setIsDragging] = useState(false)
  const [showScrubber, setShowScrubber] = useState(false)
  const videoRef = React.useRef<HTMLVideoElement>(null)
  const progressRef = React.useRef<HTMLDivElement>(null)

  const handleVideoMouseDown = () => {
    if (videoRef.current) videoRef.current.pause()
  }

  const handleVideoMouseUp = () => {
    if (videoRef.current) videoRef.current.play()
  }

  const toggleMute = () => {
    setIsMuted(!isMuted)
    if (videoRef.current) videoRef.current.muted = !isMuted
  }

  const handleProgressClick = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!videoRef.current) return
    const rect = e.currentTarget.getBoundingClientRect()
    const clickX = e.clientX - rect.left
    const percentage = clickX / rect.width
    videoRef.current.currentTime = percentage * duration
  }

  const handleProgressDrag = (e: React.MouseEvent) => {
    if (!isDragging || !videoRef.current || !progressRef.current) return
    const rect = progressRef.current.getBoundingClientRect()
    const clickX = Math.max(0, Math.min(e.clientX - rect.left, rect.width))
    const percentage = clickX / rect.width
    videoRef.current.currentTime = percentage * duration
  }

  const handleProgressMouseDown = (e: React.MouseEvent<HTMLDivElement>) => {
    setIsDragging(true)
    setShowScrubber(true)
    handleProgressClick(e)
  }

  const handleProgressMouseUp = () => {
    setIsDragging(false)
    setTimeout(() => setShowScrubber(false), 1000)
  }

  React.useEffect(() => {
    if (isDragging) {
      window.addEventListener('mousemove', handleProgressDrag as any)
      window.addEventListener('mouseup', handleProgressMouseUp)
      return () => {
        window.removeEventListener('mousemove', handleProgressDrag as any)
        window.removeEventListener('mouseup', handleProgressMouseUp)
      }
    }
  }, [isDragging])

  useEffect(() => {
    if (!reelId) return
    fetchReel()
    const interval = setInterval(() => {
      fetchReel()
    }, 5000)
    return () => clearInterval(interval)
  }, [reelId])

  const fetchReel = async () => {
    if (!reelId) return
    try {
      const res = await fetch(`/api/reels/${reelId}`, { cache: 'no-store' })
      const data = await res.json()
      setReel(data.reel)
    } catch (err) {
      console.error('Failed to fetch reel:', err)
    } finally {
      setLoading(false)
    }
  }

  const handlePublish = async () => {
    if (!reelId || !confirm('Publish this reel?')) return
    
    try {
      const res = await fetch(`/api/reels/${reelId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          status: 'published',
          publishedAt: new Date().toISOString()
        })
      })
      
      if (res.ok) {
        alert('Reel published successfully!')
        fetchReel()
      } else {
        alert('Failed to publish reel')
      }
    } catch (err) {
      console.error('Publish error:', err)
      alert('Error publishing reel')
    }
  }

  if (loading) return (
    <div style={{ display: 'flex' }}>
      <Sidebar />
      <div style={{ marginLeft: '250px', padding: '20px' }}>Loading...</div>
    </div>
  )
  
  if (!reel) return (
    <div style={{ display: 'flex' }}>
      <Sidebar />
      <div style={{ marginLeft: '250px', padding: '20px' }}>Reel not found</div>
    </div>
  )

  return (
    <div style={{ display: 'flex' }}>
      <Sidebar />
      <div className={styles.container}>
      <button className={styles.backArrow} onClick={() => router.push('/reels')}>
        ⬅
      </button>

      <div className={styles.content}>
        <div className={styles.videoSection}>
          <div className={styles.videoPlayer}>
            <div style={{ position: 'absolute', top: '0', left: '0', right: '0', height: '60px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 15px', zIndex: 10, background: 'linear-gradient(to bottom, rgba(0,0,0,0.4), transparent)' }}>
              <span onClick={() => router.push('/reels')} style={{ color: 'white', fontSize: '24px', cursor: 'pointer' }}>←</span>
              <span style={{ color: 'white', fontSize: '18px', fontWeight: '600', letterSpacing: '1px' }}>asiaze</span>
              <span onClick={toggleMute} style={{ color: 'white', fontSize: '24px', cursor: 'pointer' }} title={isMuted ? "Unmute" : "Mute"}>{isMuted ? '🔇' : '🔊'}</span>
            </div>
            <div style={{ position: 'absolute', right: '12px', bottom: '140px', display: 'flex', flexDirection: 'column', gap: '20px', zIndex: 10, alignItems: 'center' }}>
              <div style={{ textAlign: 'center' }} onClick={() => setIsLiked(!isLiked)}>
                <div style={{ width: '50px', height: '50px', borderRadius: '50%', border: '2px solid white', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', background: isLiked ? 'red' : 'transparent' }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill={isLiked ? 'white' : 'none'} stroke="white" strokeWidth="2">
                    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
                  </svg>
                </div>
                <span style={{ color: 'white', fontSize: '12px', marginTop: '4px', display: 'block', fontWeight: '600', textShadow: '0 1px 2px rgba(0,0,0,0.5)' }}>{reel.likes >= 1000 ? `${(reel.likes / 1000).toFixed(1)}K` : reel.likes || 0}</span>
              </div>
              <div style={{ textAlign: 'center' }} onClick={() => setIsSaved(!isSaved)}>
                <div style={{ width: '50px', height: '50px', borderRadius: '50%', border: '2px solid white', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', background: isSaved ? 'white' : 'transparent' }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill={isSaved ? 'black' : 'none'} stroke={isSaved ? 'black' : 'white'} strokeWidth="2">
                    <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"></path>
                  </svg>
                </div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ width: '50px', height: '50px', borderRadius: '50%', border: '2px solid white', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', background: 'transparent' }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2">
                    <line x1="22" y1="2" x2="11" y2="13"></line>
                    <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                  </svg>
                </div>
              </div>
            </div>
            <div 
              className={styles.videoContent}
              onMouseDown={handleVideoMouseDown}
              onMouseUp={handleVideoMouseUp}
              onMouseLeave={handleVideoMouseUp}
              onTouchStart={handleVideoMouseDown}
              onTouchEnd={handleVideoMouseUp}
            >
              {reel.videoUrl ? (
                <video 
                  ref={videoRef}
                  key={reel.videoUrl}
                  src={reel.videoUrl} 
                  className={styles.videoImg} 
                  autoPlay
                  loop
                  muted={isMuted}
                  playsInline
                  onTimeUpdate={(e) => setCurrentTime(e.currentTarget.currentTime)}
                  onLoadedMetadata={(e) => setDuration(e.currentTarget.duration)}
                  onError={(e) => console.error('Video load error:', e)}
                />
              ) : (
                <img src="/placeholder-video.jpg" alt="Reel" className={styles.videoImg} />
              )}
            </div>
            <div className={styles.videoInfo}>
              <h3 className={styles.videoTitle}>{reel.title}</h3>
              <p className={styles.videoMeta}>{reel.source || 'ASIAZE'} · {new Date(reel.createdAt).toLocaleDateString()}</p>
              <p className={styles.videoCaption}>{reel.description}</p>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '12px' }}>
                <span style={{ fontSize: '12px', color: '#ddd' }}>
                  {Math.floor(currentTime / 60)}:{String(Math.floor(currentTime % 60)).padStart(2, '0')} / {Math.floor(duration / 60)}:{String(Math.floor(duration % 60)).padStart(2, '0')}
                </span>
                <div style={{ display: 'flex', gap: '12px', fontSize: '11px', color: '#ddd' }}>
                  <span>Swipe up ↑</span>
                  <span>Tap to open article</span>
                </div>
              </div>
              <div 
                ref={progressRef}
                onMouseDown={handleProgressMouseDown}
                style={{ width: '100%', height: '6px', background: 'rgba(255,255,255,0.3)', borderRadius: '3px', marginTop: '8px', position: 'relative', cursor: 'pointer' }}
              >
                <div className={styles.progressBar} style={{ width: `${duration > 0 ? (currentTime / duration) * 100 : 0}%`, height: '100%', position: 'relative', transition: isDragging ? 'none' : 'width 0.1s linear' }}>
                  {showScrubber && (
                    <div style={{ position: 'absolute', right: '-6px', top: '50%', transform: 'translateY(-50%)', width: '12px', height: '12px', borderRadius: '50%', background: 'white', boxShadow: '0 2px 4px rgba(0,0,0,0.3)', cursor: 'grab' }}></div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className={styles.metadataSection}>
          <h2 className={styles.metadataTitle}>Reel Metadata</h2>

          <div className={styles.metadataItem}>
            <label className={styles.metadataLabel}>Title:</label>
            <p className={styles.metadataValue}>{reel.title}</p>
          </div>

          <div className={styles.metadataItem}>
            <label className={styles.metadataLabel}>Caption:</label>
            <p className={styles.metadataValue}>{reel.description || 'No description'}</p>
          </div>

          <div className={styles.metadataItem}>
            <label className={styles.metadataLabel}>Full Article Link:</label>
            {reel.fullArticleLink ? (
              <a href={reel.fullArticleLink} target="_blank" rel="noopener noreferrer" className={styles.metadataLink}>Read full article</a>
            ) : (
              <p className={styles.metadataValue}>No link</p>
            )}
          </div>

          <div className={styles.metadataItem}>
            <label className={styles.metadataLabel}>Category:</label>
            <p className={styles.metadataValue}>{reel.category?.name || 'N/A'}</p>
          </div>

          <div className={styles.metadataItem}>
            <label className={styles.metadataLabel}>Language:</label>
            <p className={styles.metadataValue}>{reel.language || 'EN'}</p>
          </div>

          <div className={styles.metadataItem}>
            <label className={styles.metadataLabel}>Tags:</label>
            <div className={styles.tags}>
              {reel.tags?.length > 0 ? (
                reel.tags.map((tag: any, i: number) => (
                  <span key={i} className={styles.tag}>{tag.name || tag}</span>
                ))
              ) : (
                <p className={styles.metadataValue}>No tags</p>
              )}
            </div>
          </div>

          <div className={styles.metadataItem}>
            <label className={styles.metadataLabel}>Views & Likes:</label>
            <p className={styles.metadataValue}>{reel.views || 0} views · {reel.likes || 0} likes</p>
          </div>

          <div className={styles.metadataItem}>
            <label className={styles.metadataLabel}>Status:</label>
            <p className={styles.metadataValue}>{reel.status}</p>
          </div>

          <div className={styles.buttonRow}>
            {reel.status === 'draft' && (
              <button className={styles.publishBtn} onClick={handlePublish}>Publish Reel</button>
            )}
            <button className={styles.editBtn} onClick={() => reelId && router.push(`/reels/edit/${reelId}`)}>Edit Reel</button>
            <button className={styles.backBtn} onClick={() => router.push('/reels')}>Back to All Reels</button>
          </div>
        </div>
      </div>
      </div>
    </div>
  )
}
