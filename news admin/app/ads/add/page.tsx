'use client'

import Sidebar from '@/components/Sidebar'
import { useState } from 'react'
import styles from './page.module.css'

export default function AddAdvertisementPage() {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    imageUrl: '',
    clickUrl: '',
    position: 'inline',
    status: 'active',
    startDate: '',
    endDate: '',
    showInArticles: false,
    showInReels: false,
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
  }

  const handleCheckbox = (name: string, checked: boolean) => {
    setFormData(prev => ({ ...prev, [name]: checked }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
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
          clickUrl: '',
          position: 'inline',
          status: 'active',
          startDate: '',
          endDate: '',
          showInArticles: false,
          showInReels: false,
        })
      }
    } catch (error) {
      console.error('Error adding advertisement:', error)
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
            <div className={styles.formGroup}>
              <label>Title *</label>
              <input
                type="text"
                name="title"
                value={formData.title}
                onChange={handleChange}
                required
                className={styles.input}
              />
            </div>

            <div className={styles.formGroup}>
              <label>Description</label>
              <textarea
                name="description"
                value={formData.description}
                onChange={handleChange}
                className={styles.textarea}
                rows={3}
              />
            </div>

            <div className={styles.formGroup}>
              <label>Image URL *</label>
              <input
                type="text"
                name="imageUrl"
                value={formData.imageUrl}
                onChange={handleChange}
                required
                className={styles.input}
                placeholder="https://example.com/ad-image.jpg"
              />
            </div>

            <div className={styles.formGroup}>
              <label>Click URL *</label>
              <input
                type="text"
                name="clickUrl"
                value={formData.clickUrl}
                onChange={handleChange}
                required
                className={styles.input}
                placeholder="https://example.com/landing-page"
              />
            </div>

            {/* Show In Section */}
            <div className={styles.formGroup}>
              <label style={{ fontWeight: '700', fontSize: '15px', marginBottom: '12px', display: 'block' }}>
                Show In *
              </label>
              <div style={{ display: 'flex', gap: '30px' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '10px', cursor: 'pointer', fontSize: '15px' }}>
                  <input
                    type="checkbox"
                    checked={formData.showInArticles}
                    onChange={(e) => handleCheckbox('showInArticles', e.target.checked)}
                    style={{ width: '18px', height: '18px', cursor: 'pointer' }}
                  />
                  <span>Articles (News Feed)</span>
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: '10px', cursor: 'pointer', fontSize: '15px' }}>
                  <input
                    type="checkbox"
                    checked={formData.showInReels}
                    onChange={(e) => handleCheckbox('showInReels', e.target.checked)}
                    style={{ width: '18px', height: '18px', cursor: 'pointer' }}
                  />
                  <span>Reels (Video Feed)</span>
                </label>
              </div>
              <p style={{ fontSize: '12px', color: '#888', marginTop: '8px' }}>
                Ad will appear between content in selected sections
              </p>
            </div>

            <div className={styles.formGroup}>
              <label>Status *</label>
              <select
                name="status"
                value={formData.status}
                onChange={handleChange}
                className={styles.select}
              >
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
                <option value="scheduled">Scheduled</option>
              </select>
            </div>

            <div className={styles.formRow}>
              <div className={styles.formGroup}>
                <label>Start Date</label>
                <input
                  type="datetime-local"
                  name="startDate"
                  value={formData.startDate}
                  onChange={handleChange}
                  className={styles.input}
                />
              </div>

              <div className={styles.formGroup}>
                <label>End Date</label>
                <input
                  type="datetime-local"
                  name="endDate"
                  value={formData.endDate}
                  onChange={handleChange}
                  className={styles.input}
                />
              </div>
            </div>

            <div className={styles.buttonRow}>
              <button type="submit" className={styles.submitBtn}>
                Add Advertisement
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
