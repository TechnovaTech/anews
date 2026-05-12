'use client'

import React, { useState, useEffect, use } from 'react'
import Sidebar from '@/components/Sidebar'
import { useRouter } from 'next/navigation'
import styles from './page.module.css'

export default function EditReelPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
  const router = useRouter()
  const [loading, setLoading] = useState(true)
  const [videoFile, setVideoFile] = useState<File | null>(null)
  const [uploading, setUploading] = useState(false)
  const [formData, setFormData] = useState({
    title: '',
    summary: '',
    fullArticleLink: '',
    category: '',
    language: 'EN',
    tags: [] as string[],
    sourceName: '',
    duration: '',
    videoUrl: '',
    thumbnail: '',
    videoPreview: '',
    thumbnailPreview: '',
    featured: false,
    enableComments: true
  })

  useEffect(() => {
    fetchReel()
  }, [id])

  const fetchReel = async () => {
    try {
      const res = await fetch(`/api/reels/${id}`)
      const data = await res.json()
      const reel = data.reel
      setFormData({
        title: reel.title || '',
        summary: reel.description || '',
        fullArticleLink: reel.fullArticleLink || '',
        category: reel.category?._id || '',
        language: reel.language || 'EN',
        tags: reel.tags?.map((t: any) => t.name || t) || [],
        sourceName: reel.source || '',
        duration: reel.duration || '',
        videoUrl: reel.videoUrl || '',
        thumbnail: reel.thumbnail || '',
        videoPreview: '',
        thumbnailPreview: '',
        featured: reel.featured || false,
        enableComments: reel.enableComments !== false
      })
    } catch (err) {
      console.error('Failed to fetch reel:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
  }

  const uploadVideo = async () => {
    if (!videoFile) return null
    
    setUploading(true)
    try {
      const chunkSize = 5 * 1024 * 1024; // 5MB chunks
      const totalChunks = Math.ceil(videoFile.size / chunkSize);
      const filename = `${Date.now()}-${videoFile.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`;

      for (let i = 0; i < totalChunks; i++) {
        const start = i * chunkSize;
        const end = Math.min(start + chunkSize, videoFile.size);
        const chunk = videoFile.slice(start, end);
        
        const reader = new FileReader();
        const base64Promise = new Promise<string>((resolve) => {
          reader.onloadend = () => resolve(reader.result as string);
          reader.readAsDataURL(chunk);
        });
        
        const chunkData = await base64Promise;

        const res = await fetch('/api/upload/video', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 
            chunkData, 
            filename,
            chunkIndex: i,
            totalChunks
          })
        });

        if (!res.ok) return null;
      }

      return `/uploads/videos/${filename}`;
    } catch (error) {
      console.error('Upload error:', error)
      return null
    } finally {
      setUploading(false)
    }
  }

  const handleThumbnailUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      const reader = new FileReader()
      reader.onloadend = () => {
        const base64 = reader.result as string
        setFormData(prev => ({ ...prev, thumbnail: base64, thumbnailPreview: base64 }))
      }
      reader.readAsDataURL(file)
    }
  }

  const handleToggle = (field: 'featured' | 'enableComments') => {
    setFormData(prev => ({ ...prev, [field]: !prev[field] }))
  }

  const handleUpdate = async () => {
    try {
      setLoading(true)
      
      let videoUrl = formData.videoUrl
      if (videoFile) {
        const uploadedUrl = await uploadVideo()
        if (uploadedUrl) {
          videoUrl = uploadedUrl
        } else {
          alert('Failed to upload video')
          setLoading(false)
          return
        }
      }
      
      const updateData = {
        title: formData.title,
        description: formData.summary,
        fullArticleLink: formData.fullArticleLink,
        category: formData.category,
        language: formData.language,
        source: formData.sourceName,
        duration: formData.duration,
        videoUrl: videoUrl,
        thumbnail: formData.thumbnail,
        featured: formData.featured,
        enableComments: formData.enableComments
      }
      
      const res = await fetch(`/api/reels/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updateData)
      })
      
      if (res.ok) {
        alert('Reel updated successfully!')
        router.push('/reels')
      } else {
        alert('Failed to update reel')
      }
    } catch (err) {
      console.error('Update error:', err)
      alert('Error updating reel')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className={styles.container}>
      <Sidebar />
      <div className={styles.main}>
        <div className={styles.content}>
          <div className={styles.formGrid}>
            <div>
              <div className={styles.formGroup}>
                <label className={styles.label}>Reel Title/Headline</label>
                <input
                  type="text"
                  name="title"
                  value={formData.title}
                  onChange={handleChange}
                  placeholder="Current Reel Title"
                  className={styles.input}
                />
              </div>

              <div className={styles.formGroup}>
                <label className={styles.label}>Summary/Caption</label>
                <textarea
                  name="summary"
                  value={formData.summary}
                  onChange={handleChange}
                  placeholder="Current summary text, limited to 60 words."
                  className={styles.textarea}
                />
              </div>

              <div className={styles.formGroup}>
                <label className={styles.label}>Full Article Link</label>
                <input
                  type="text"
                  name="fullArticleLink"
                  value={formData.fullArticleLink}
                  onChange={handleChange}
                  placeholder="https://currentarticlelink.com"
                  className={styles.input}
                />
              </div>

              <div className={styles.formGroup}>
                <label className={styles.label}>Category</label>
                <select
                  name="category"
                  value={formData.category}
                  onChange={handleChange}
                  className={styles.select}
                >
                  <option>Current Category</option>
                  <option>Politics</option>
                  <option>Entertainment</option>
                  <option>Finance</option>
                  <option>Sports</option>
                </select>
              </div>

              <div className={styles.formGroup}>
                <label className={styles.label}>Language</label>
                <select
                  name="language"
                  value={formData.language}
                  onChange={handleChange}
                  className={styles.select}
                >
                  <option value="EN">EN</option>
                  <option value="HIN">HIN</option>
                  <option value="BEN">BEN</option>
                </select>
              </div>

              <div className={styles.formGroup}>
                <label className={styles.label}>Tags</label>
                <div className={styles.tagsContainer}>
                  {formData.tags.map((tag, index) => (
                    <span key={index} className={styles.tag}>{tag}</span>
                  ))}
                </div>
              </div>
            </div>

            <div>
              <div className={styles.formGroup}>
                <label className={styles.label}>Replace Video (Optional)</label>
                {uploading && <div style={{color: 'blue'}}>Uploading...</div>}
                {videoFile && <div style={{color: 'green'}}>New video selected: {videoFile.name}</div>}
                <input
                  type="file"
                  accept="video/*"
                  onChange={(e) => {
                    const file = e.target.files?.[0]
                    if (file) {
                      setVideoFile(file)
                      setFormData(prev => ({ ...prev, videoPreview: URL.createObjectURL(file) }))
                    }
                  }}
                  className={styles.input}
                />
                <div className={styles.videoPreview}>
                  {(formData.videoPreview || formData.videoUrl) ? (
                    <video 
                      key={formData.videoPreview || formData.videoUrl}
                      src={formData.videoPreview || formData.videoUrl} 
                      controls 
                      style={{ width: '100%', height: '100%', objectFit: 'contain' }}
                      onError={(e) => console.error('Video load error:', e)}
                    />
                  ) : (
                    <div className={styles.previewText}>No Video</div>
                  )}
                </div>
              </div>

              <div className={styles.formGroup}>
                <label className={styles.label}>Current Thumbnail</label>
                <div className={styles.thumbnailPreview}>
                  {(formData.thumbnailPreview || formData.thumbnail) ? (
                    <img src={formData.thumbnailPreview || formData.thumbnail} alt="Thumbnail" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                  ) : (
                    <div className={styles.previewText}>No Thumbnail</div>
                  )}
                </div>
                <input
                  type="file"
                  id="thumbnailUpload"
                  accept="image/*"
                  onChange={handleThumbnailUpload}
                  style={{ display: 'none' }}
                />
                <button type="button" className={styles.replaceBtn} onClick={() => document.getElementById('thumbnailUpload')?.click()}>
                  Replace Thumbnail
                </button>
              </div>

              <div className={styles.formGroup}>
                <label className={styles.label}>Source Name</label>
                <input
                  type="text"
                  name="sourceName"
                  value={formData.sourceName}
                  onChange={handleChange}
                  placeholder="Current Source Name"
                  className={styles.input}
                />
              </div>

              <div className={styles.formGroup}>
                <label className={styles.label}>Duration</label>
                <input
                  type="text"
                  name="duration"
                  value={formData.duration}
                  onChange={handleChange}
                  placeholder="00:02:30"
                  className={styles.input}
                />
              </div>

              <div className={styles.toggleRow}>
                <div className={styles.toggleGroup}>
                  <label className={styles.label}>Featured/Breaking</label>
                  <div 
                    className={`${styles.toggle} ${formData.featured ? styles.toggleActive : ''}`}
                    onClick={() => handleToggle('featured')}
                  >
                    <div className={styles.toggleCircle}></div>
                  </div>
                </div>

                <div className={styles.toggleGroup}>
                  <label className={styles.label}>Enable Comments</label>
                  <div 
                    className={`${styles.toggle} ${formData.enableComments ? styles.toggleActive : ''}`}
                    onClick={() => handleToggle('enableComments')}
                  >
                    <div className={styles.toggleCircle}></div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className={styles.buttonRow}>
            <button onClick={() => router.push('/reels')} className={styles.cancelBtn}>Cancel</button>
            <button onClick={handleUpdate} className={styles.updateBtn}>Update</button>
          </div>
        </div>
      </div>
    </div>
  )
}
