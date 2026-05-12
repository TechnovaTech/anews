'use client'

import Sidebar from '@/components/Sidebar'
import { useState } from 'react'
import styles from './page.module.css'

export default function AddAdvertisementPage() {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    imageUrl: '',
    videoUrl: '',
    adType: 'image',
    clickUrl: '',
    status: 'active',
    startDate: '',
    endDate: '',
    showInArticles: false,
    showInReels: false,
  })
  const [uploading, setUploading] = useState(false)

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
  }

  const handleCheckbox = (name: string, checked: boolean) => {
    setFormData(prev => ({ ...prev, [name]: checked }))
  }

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setUploading(true)
    try {
      const fd = new FormData()
      fd.append('file', file)
      const res = await fetch('/api/upload', { method: 'POST', body: fd })
      const data = await res.json()
      setFormData(prev => ({ ...prev, imageUrl: data.url, adType: 'image' }))
    } catch {
      alert('Image upload failed')
    } finally {
      setUploading(false)
    }
  }

  const handleVideoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setUploading(true)
    try {
      const fd = new FormData()
      fd.append('video', file)
      const res = await fetch('/api/upload/video', { method: 'POST', body: fd })
      const data = await res.json()
      setFormData(prev => ({ ...prev, videoUrl: data.videoUrl, adType: 'video' }))
    } catch {
      alert('Video upload failed')
    } finally {
      setUploading(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (formData.adType === 'image' && !formData.imageUrl) {
      alert('Please upload an image')
      return
    }
    if (formData.adType === 'video' && !formData.videoUrl) {
      alert('Please upload a video')
      return
    }
    if (!formData.showInArticles && !formData.showInReels) {
      alert('Please select at least one placement (Articles or Reels)')
      return
    }
    try {
      const response = await fetch('/api/ads', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      })
      if (response.ok) {
        alert('Advertisement added successfully!')
        setFormData({
          title: '',
          description: '',
          imageUrl: '',
          videoUrl: '',
          adType: 'image',
          clickUrl: '',
          status: 'active',
          startDate: '',
          endDate: '',
          showInArticles: false,
          showInReels: false,
        })
      }
    } catch (error) {
      alert('Failed to add advertisement')
    }
  }

  return (
    <div className={styles.container}>
      <Sidebar />
      <div className={styles.main}>
        <div className={styles.content}>
          <h1 className={styles.title}>Add Advertisement</h1>

          <form onSubmit={handleSubmit} className={styles.form}>

            {/* Title */}
            <div className={styles.formGroup}>
              <label>Title *</label>
              <input type="text" name="title" value={formData.title} onChange={handleChange} required className={styles.input} />
            </div>

            {/* Description */}
            <div className={styles.formGroup}>
              <label>Description</label>
              <textarea name="description" value={formData.description} onChange={handleChange} className={styles.textarea} rows={3} />
            </div>

            {/* Ad Type */}
            <div className={styles.formGroup}>
              <label style={{ fontWeight: '700', fontSize: '15px', marginBottom: '12px', display: 'block' }}>Ad Type *</label>
              <div style={{ display: 'flex', gap: '30px', marginBottom: '16px' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '10px', cursor: 'pointer', fontSize: '15px' }}>
                  <input
                    type="radio"
                    name="adType"
                    value="image"
                    checked={formData.adType === 'image'}
                    onChange={handleChange}
                    style={{ width: '18px', height: '18px' }}
                  />
                  <span>🖼️ Image Ad</span>
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: '10px', cursor: 'pointer', fontSize: '15px' }}>
                  <input
                    type="radio"
                    name="adType"
                    value="video"
                    checked={formData.adType === 'video'}
                    onChange={handleChange}
                    style={{ width: '18px', height: '18px' }}
                  />
                  <span>🎬 Video Ad</span>
                </label>
              </div>

              {/* Image Upload */}
              {formData.adType === 'image' && (
                <div>
                  <input type="file" accept="image/*" onChange={handleImageUpload} className={styles.input} disabled={uploading} />
                  {uploading && <p style={{ color: '#e31e3a', fontSize: '13px', marginTop: '6px' }}>Uploading...</p>}
                  {formData.imageUrl && (
                    <div style={{ marginTop: '10px' }}>
                      <img src={formData.imageUrl} alt="Ad preview" style={{ width: '100%', maxHeight: '200px', objectFit: 'cover', borderRadius: '8px' }} />
                    </div>
                  )}
                </div>
              )}

              {/* Video Upload */}
              {formData.adType === 'video' && (
                <div>
                  <input type="file" accept="video/*" onChange={handleVideoUpload} className={styles.input} disabled={uploading} />
                  {uploading && <p style={{ color: '#e31e3a', fontSize: '13px', marginTop: '6px' }}>Uploading...</p>}
                  {formData.videoUrl && (
                    <div style={{ marginTop: '10px' }}>
                      <video src={formData.videoUrl} controls style={{ width: '100%', maxHeight: '200px', borderRadius: '8px' }} />
                    </div>
                  )}
                </div>
              )}
            </div>

            {/* Click URL */}
            <div className={styles.formGroup}>
              <label>Click URL *</label>
              <input type="text" name="clickUrl" value={formData.clickUrl} onChange={handleChange} required className={styles.input} placeholder="https://example.com/landing-page" />
            </div>

            {/* Show In */}
            <div className={styles.formGroup}>
              <label style={{ fontWeight: '700', fontSize: '15px', marginBottom: '12px', display: 'block' }}>Show In *</label>
              <div style={{ display: 'flex', gap: '30px' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '10px', cursor: 'pointer', fontSize: '15px' }}>
                  <input
                    type="checkbox"
                    checked={formData.showInArticles}
                    onChange={(e) => handleCheckbox('showInArticles', e.target.checked)}
                    style={{ width: '18px', height: '18px', cursor: 'pointer' }}
                  />
                  <span>📰 Articles (News Feed)</span>
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: '10px', cursor: 'pointer', fontSize: '15px' }}>
                  <input
                    type="checkbox"
                    checked={formData.showInReels}
                    onChange={(e) => handleCheckbox('showInReels', e.target.checked)}
                    style={{ width: '18px', height: '18px', cursor: 'pointer' }}
                  />
                  <span>🎬 Reels (Video Feed)</span>
                </label>
              </div>
              <p style={{ fontSize: '12px', color: '#888', marginTop: '8px' }}>Ad will appear between content in selected sections</p>
            </div>

            {/* Status */}
            <div className={styles.formGroup}>
              <label>Status *</label>
              <select name="status" value={formData.status} onChange={handleChange} className={styles.select}>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
                <option value="scheduled">Scheduled</option>
              </select>
            </div>

            {/* Dates */}
            <div className={styles.formRow}>
              <div className={styles.formGroup}>
                <label>Start Date</label>
                <input type="datetime-local" name="startDate" value={formData.startDate} onChange={handleChange} className={styles.input} />
              </div>
              <div className={styles.formGroup}>
                <label>End Date</label>
                <input type="datetime-local" name="endDate" value={formData.endDate} onChange={handleChange} className={styles.input} />
              </div>
            </div>

            <div className={styles.buttonRow}>
              <button type="submit" className={styles.submitBtn} disabled={uploading}>
                {uploading ? 'Uploading...' : 'Add Advertisement'}
              </button>
              <button type="button" className={styles.cancelBtn} onClick={() => window.history.back()}>
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}
