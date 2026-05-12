'use client'

import React, { useState, useEffect } from 'react'
import Sidebar from '@/components/Sidebar'
import { useRouter } from 'next/navigation'
import styles from './page.module.css'

export default function AddReelPage() {
  const router = useRouter()
  const [categories, setCategories] = useState<any[]>([])
  const [existingTags, setExistingTags] = useState<any[]>([])
  const [loading, setLoading] = useState(false)
  const [showTagDropdown, setShowTagDropdown] = useState(false)
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    fullArticleLink: '',
    videoUrl: '',
    thumbnail: '',
    category: '',
    language: 'EN',
    tags: [] as string[],
    currentTag: '',
    status: 'published',
    videoPreview: '',
    thumbnailPreview: '',
    featured: true,
    enableComments: true
  })
  const [videoFile, setVideoFile] = useState<File | null>(null)
  const [uploading, setUploading] = useState(false)

  useEffect(() => {
    fetchCategories()
    fetchTags()
  }, [])

  const fetchCategories = async () => {
    try {
      const res = await fetch('/api/categories')
      const data = await res.json()
      setCategories(data.categories || [])
      if (data.categories?.length > 0) {
        setFormData(prev => ({ ...prev, category: data.categories[0]._id }))
      }
    } catch (err) {
      console.error('Failed to fetch categories:', err)
    }
  }

  const fetchTags = async () => {
    try {
      const res = await fetch('/api/tags')
      const data = await res.json()
      setExistingTags(data.filter((tag: any) => tag.isActive))
    } catch (err) {
      console.error('Failed to fetch tags:', err)
    }
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
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

  const handleAddTag = async () => {
    const tagName = formData.currentTag?.trim()
    if (tagName && !formData.tags.includes(tagName)) {
      const tagExists = existingTags.find(t => t.name.toLowerCase() === tagName.toLowerCase())
      if (!tagExists) {
        try {
          await fetch('/api/tags', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: tagName, isActive: true })
          })
          fetchTags()
        } catch (err) {
          console.error('Failed to create tag:', err)
        }
      }
      setFormData(prev => ({ ...prev, tags: [...prev.tags, tagName], currentTag: '' }))
      setShowTagDropdown(false)
    }
  }

  const handleSelectTag = (tagName: string) => {
    if (!formData.tags.includes(tagName)) {
      setFormData(prev => ({ ...prev, tags: [...prev.tags, tagName], currentTag: '' }))
    }
    setShowTagDropdown(false)
  }

  const handleRemoveTag = (tagToRemove: string) => {
    setFormData(prev => ({ ...prev, tags: prev.tags.filter(tag => tag !== tagToRemove) }))
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

  const handleSubmit = async (status: string) => {
    if (!formData.title || !formData.category) {
      alert('Please fill in Title and Category')
      return
    }
    if (!videoFile) {
      alert('Please upload a video')
      return
    }

    setLoading(true)
    try {
      const videoUrl = await uploadVideo()
      if (!videoUrl) {
        alert('Failed to upload video')
        setLoading(false)
        return
      }

      const res = await fetch('/api/reels', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: formData.title,
          description: formData.description,
          fullArticleLink: formData.fullArticleLink,
          videoUrl: videoUrl,
          thumbnail: formData.thumbnail,
          category: formData.category,
          language: formData.language,
          tags: formData.tags,
          featured: formData.featured,
          enableComments: formData.enableComments,
          status: status,
          publishedAt: status === 'published' ? new Date().toISOString() : null
        })
      })

      if (res.ok) {
        alert(`Reel ${status} successfully!`)
        router.push('/reels')
      } else {
        const error = await res.json()
        alert(`Failed to ${status} reel: ${error.error}`)
      }
    } catch (err) {
      console.error('Error:', err)
      alert('Failed to save reel')
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
                  placeholder="Enter title"
                  className={styles.input}
                />
              </div>

              <div className={styles.formGroup}>
                <label className={styles.label}>Summary/Caption</label>
                <textarea
                  name="description"
                  value={formData.description}
                  onChange={handleChange}
                  placeholder="Enter summary"
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
                  placeholder="Enter URL"
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
                  {categories.map(cat => (
                    <option key={cat._id} value={cat._id}>{cat.name}</option>
                  ))}
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
                <div style={{ position: 'relative' }}>
                  <div className={styles.tagInputContainer}>
                    <input
                      type="text"
                      name="currentTag"
                      value={formData.currentTag}
                      onChange={handleChange}
                      onFocus={() => setShowTagDropdown(true)}
                      onBlur={() => setTimeout(() => setShowTagDropdown(false), 200)}
                      placeholder="Type to add tags"
                      className={styles.tagInput}
                    />
                    <button type="button" onClick={handleAddTag} className={styles.addTagBtn}>Add</button>
                    <button type="button" onClick={() => setShowTagDropdown(!showTagDropdown)} className={styles.dropdownBtn}>▼</button>
                  </div>
                  {showTagDropdown && existingTags.length > 0 && (
                    <div className={styles.tagDropdown}>
                      {existingTags
                        .filter(tag => !formData.tags.includes(tag.name) && tag.name.toLowerCase().includes((formData.currentTag || '').toLowerCase()))
                        .slice(0, 10)
                        .map(tag => (
                          <div key={tag._id} className={styles.tagDropdownItem} onMouseDown={(e) => { e.preventDefault(); handleSelectTag(tag.name); }}>
                            {tag.name}
                          </div>
                        ))
                      }
                    </div>
                  )}
                </div>
                <div className={styles.tagsContainer}>
                  {formData.tags.map((tag, index) => (
                    <span key={index} className={styles.tag}>
                      {tag}
                      <button type="button" onClick={() => handleRemoveTag(tag)} className={styles.removeTagBtn}>×</button>
                    </span>
                  ))}
                </div>
              </div>
            </div>

            <div>
              <div className={styles.formGroup}>
                <label className={styles.label}>Upload Video</label>
                {uploading && <div style={{color: 'blue'}}>Uploading...</div>}
                {videoFile && <div style={{color: 'green'}}>Selected: {videoFile.name}</div>}
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
                {formData.videoPreview && (
                  <video src={formData.videoPreview} controls style={{width: '100%', marginTop: '10px'}} />
                )}
              </div>

              <div className={styles.formGroup}>
                <label className={styles.label}>Upload Thumbnail (Optional)</label>
                <div className={styles.thumbnailBox} onClick={() => document.getElementById('thumbnailUpload')?.click()}>
                  {formData.thumbnailPreview ? (
                    <img src={formData.thumbnailPreview} alt="Thumbnail" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                  ) : (
                    <>
                      <div className={styles.uploadIcon}>⬆</div>
                      <div className={styles.thumbnailText}>Click to upload thumbnail</div>
                    </>
                  )}
                </div>
                <input
                  type="file"
                  id="thumbnailUpload"
                  accept="image/*"
                  onChange={handleThumbnailUpload}
                  style={{ display: 'none' }}
                />
              </div>

              <div className={styles.toggleGroup}>
                <label className={styles.label}>Featured</label>
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

          <div className={styles.buttonRow}>
            <button type="button" onClick={() => router.push('/reels')} className={styles.cancelBtn}>Cancel</button>
            <button type="button" onClick={() => handleSubmit('draft')} disabled={loading} className={styles.draftBtn}>
              {loading ? 'Saving...' : 'Save Draft'}
            </button>
            <button type="button" onClick={() => handleSubmit('published')} disabled={loading} className={styles.publishBtn}>
              {loading ? 'Publishing...' : 'Publish'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
