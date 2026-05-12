'use client'

import Sidebar from '@/components/Sidebar'
import { useState, useEffect } from 'react'
import styles from './page.module.css'

export default function PushNotificationsPage() {
  const [formData, setFormData] = useState({
    title: '',
    message: '',
    link: '',
    allUsers: false,
    categories: [] as string[],
    languages: [] as string[],
    sendNow: false,
    scheduleForLater: false,
    scheduleDate: ''
  })

  const [timeFilter, setTimeFilter] = useState('1')
  const [recentContent, setRecentContent] = useState<any[]>([])
  const [loading, setLoading] = useState(false)
  const [selectedItem, setSelectedItem] = useState<string | null>(null)

  useEffect(() => {
    fetchRecentContent()
  }, [timeFilter])

  const fetchRecentContent = async () => {
    setLoading(true)
    try {
      const hours = parseInt(timeFilter)
      const sinceDate = new Date(Date.now() - hours * 60 * 60 * 1000)
      
      const [newsRes, storiesRes, reelsRes] = await Promise.all([
        fetch('/api/news?status=all').then(r => r.json()),
        fetch('/api/stories').then(r => r.json()),
        fetch('/api/reels?status=all').then(r => r.json())
      ])

      const newsData = newsRes.news || []
      const storiesData = storiesRes.stories || []
      const reelsData = reelsRes.reels || []

      const filterByTime = (item: any) => {
        const itemDate = new Date(item.publishedAt || item.createdAt)
        return itemDate >= sinceDate
      }

      const combined = [
        ...newsData.filter(filterByTime).map((item: any) => ({ ...item, type: 'News', publishedAt: item.publishedAt || item.createdAt })),
        ...storiesData.filter(filterByTime).map((item: any) => ({ ...item, type: 'Story', publishedAt: item.publishedAt || item.createdAt })),
        ...reelsData.filter(filterByTime).map((item: any) => ({ ...item, type: 'Reel', publishedAt: item.publishedAt || item.createdAt }))
      ].sort((a, b) => new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime())

      setRecentContent(combined)
    } catch (error) {
      console.error('Error fetching content:', error)
    }
    setLoading(false)
  }

  const formatDateTime = (date: string) => {
    return new Date(date).toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const handleSelectItem = (itemId: string) => {
    setSelectedItem(itemId)
    const item = recentContent.find(c => c._id === itemId)
    if (item) {
      setFormData(prev => ({
        ...prev,
        title: item.title || item.heading || '',
        message: (item.summary || item.description || item.content || '').substring(0, 200),
        link: item._id || ''
      }))
    }
  }

  const getLanguages = (item: any) => {
    if (item.languages && Array.isArray(item.languages)) {
      return item.languages.join(', ')
    }
    if (item.language) {
      return item.language
    }
    return 'N/A'
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
  }

  const handleCheckbox = (name: string, checked: boolean) => {
    setFormData(prev => ({ ...prev, [name]: checked }))
  }

  const handleCategoryToggle = (category: string) => {
    setFormData(prev => ({
      ...prev,
      categories: prev.categories.includes(category)
        ? prev.categories.filter(c => c !== category)
        : [...prev.categories, category]
    }))
  }

  const handleLanguageToggle = (language: string) => {
    setFormData(prev => ({
      ...prev,
      languages: prev.languages.includes(language)
        ? prev.languages.filter(l => l !== language)
        : [...prev.languages, language]
    }))
  }

  const handleSend = async () => {
    if (!selectedItem) {
      alert('Please select a content item first')
      return
    }

    const item = recentContent.find(c => c._id === selectedItem)
    if (!item) return

    try {
      // Prepare multi-language notification data
      const notificationData = {
        contentId: item._id,
        contentType: item.type,
        translations: {
          english: {
            title: item.translations?.english?.title || item.title || '',
            message: (item.translations?.english?.summary || item.summary || '').substring(0, 200)
          },
          hindi: {
            title: item.translations?.hindi?.title || item.title || '',
            message: (item.translations?.hindi?.summary || item.summary || '').substring(0, 200)
          },
          bengali: {
            title: item.translations?.bengali?.title || item.title || '',
            message: (item.translations?.bengali?.summary || item.summary || '').substring(0, 200)
          }
        },
        link: formData.link,
        audience: {
          allUsers: formData.allUsers,
          languages: formData.languages.length > 0 ? formData.languages : ['EN', 'HIN', 'BEN']
        },
        sendNow: formData.sendNow,
        scheduleDate: formData.scheduleForLater ? formData.scheduleDate : null
      }

      const response = await fetch('/api/notifications/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(notificationData)
      })

      if (response.ok) {
        alert('Notification sent successfully in all languages!')
        setSelectedItem(null)
        setFormData({
          title: '',
          message: '',
          link: '',
          allUsers: false,
          categories: [],
          languages: [],
          sendNow: false,
          scheduleForLater: false,
          scheduleDate: ''
        })
      } else {
        const error = await response.json()
        alert(`Failed to send notification: ${error.message}`)
      }
    } catch (error) {
      console.error('Error sending notification:', error)
      alert('Failed to send notification')
    }
  }

  const handleDraft = () => console.log('Draft:', formData)

  return (
    <div className={styles.container}>
      <Sidebar />
      <div className={styles.main}>
        <div className={styles.content}>
          <div className={styles.leftSection}>
            <h1 className={styles.title}>Send Notification</h1>
            
            {selectedItem && (() => {
              const item = recentContent.find(c => c._id === selectedItem)
              return item ? (
                <div style={{ 
                  padding: '15px', 
                  marginBottom: '20px', 
                  backgroundColor: '#f0f9ff', 
                  borderRadius: '8px',
                  border: '1px solid #0ea5e9',
                  position: 'relative'
                }}>
                  <button 
                    onClick={() => setSelectedItem(null)}
                    style={{
                      position: 'absolute',
                      top: '10px',
                      right: '10px',
                      background: '#ef4444',
                      color: 'white',
                      border: 'none',
                      borderRadius: '4px',
                      padding: '5px 10px',
                      cursor: 'pointer',
                      fontSize: '12px'
                    }}
                  >
                    Unselect
                  </button>
                  <h3 style={{ margin: '0 0 10px 0', color: '#0369a1' }}>Selected Content</h3>
                  <p style={{ margin: '5px 0' }}><strong>Type:</strong> {item.type}</p>
                  <p style={{ margin: '5px 0' }}><strong>Title:</strong> {item.title || item.heading || 'Untitled'}</p>
                  <p style={{ margin: '5px 0' }}><strong>Category:</strong> {item.category?.name || 'N/A'}</p>
                  <p style={{ margin: '5px 0' }}><strong>Language:</strong> {getLanguages(item)}</p>
                </div>
              ) : null
            })()}

            <input
              type="text"
              name="title"
              value={formData.title}
              onChange={handleChange}
              placeholder="Title"
              className={styles.input}
            />

            <div className={styles.textareaWrapper}>
              <textarea
                name="message"
                value={formData.message}
                onChange={handleChange}
                placeholder="Message Body (max 200 chars)"
                className={styles.textarea}
                maxLength={200}
              />
              <div className={styles.charCount}>{formData.message.length}/200</div>
            </div>

            <input
              type="text"
              name="link"
              value={formData.link}
              onChange={handleChange}
              placeholder="Link (optional)"
              className={styles.input}
            />

            <div className={styles.section}>
              <h3 className={styles.sectionTitle}>Audience Selector</h3>
              
              <label className={styles.radioLabel}>
                <input
                  type="checkbox"
                  checked={formData.allUsers}
                  onChange={(e) => handleCheckbox('allUsers', e.target.checked)}
                />
                All Users
              </label>

              {/* <div style={{ marginTop: '10px' }}>
                <strong>By Category:</strong>
                <div style={{ marginLeft: '20px', marginTop: '5px' }}>
                  {['Politics', 'Entertainment', 'Finance', 'Sports', 'Technology'].map(cat => (
                    <label key={cat} className={styles.radioLabel}>
                      <input
                        type="checkbox"
                        checked={formData.categories.includes(cat)}
                        onChange={() => handleCategoryToggle(cat)}
                      />
                      {cat}
                    </label>
                  ))}
                </div>
              </div> */}

              <div style={{ marginTop: '10px' }}>
                <strong>By Language:</strong>
                <div style={{ marginLeft: '20px', marginTop: '5px' }}>
                  {['EN', 'HIN', 'BEN'].map(lang => (
                    <label key={lang} className={styles.radioLabel}>
                      <input
                        type="checkbox"
                        checked={formData.languages.includes(lang)}
                        onChange={() => handleLanguageToggle(lang)}
                      />
                      {lang}
                    </label>
                  ))}
                </div>
              </div>
            </div>

            <div className={styles.section}>
              <label className={styles.radioLabel}>
                <input
                  type="checkbox"
                  checked={formData.sendNow}
                  onChange={(e) => handleCheckbox('sendNow', e.target.checked)}
                />
                Send Now
              </label>

              <label className={styles.radioLabel}>
                <input
                  type="checkbox"
                  checked={formData.scheduleForLater}
                  onChange={(e) => handleCheckbox('scheduleForLater', e.target.checked)}
                />
                Schedule for Later
              </label>

              {formData.scheduleForLater && (
                <input
                  type="datetime-local"
                  name="scheduleDate"
                  value={formData.scheduleDate}
                  onChange={handleChange}
                  className={styles.input}
                />
              )}
            </div>

            <div className={styles.buttonRow}>
              <button onClick={handleSend} className={styles.sendBtn}>Send Notification</button>
              <button onClick={handleDraft} className={styles.draftBtn}>Save as Draft</button>
            </div>
          </div>

          <div className={styles.rightSection}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h1 className={styles.title}>Recent Published Content</h1>
              <select 
                value={timeFilter} 
                onChange={(e) => setTimeFilter(e.target.value)} 
                className={styles.select}
                style={{ width: 'auto', padding: '8px 12px' }}
              >
                <option value="1">Last 1 Hour</option>
                <option value="6">Last 6 Hours</option>
                <option value="12">Last 12 Hours</option>
                <option value="24">Last 24 Hours</option>
              </select>
            </div>

            {loading ? (
              <div style={{ textAlign: 'center', padding: '40px' }}>Loading...</div>
            ) : (
              <table className={styles.table}>
                <thead>
                  <tr>
                    <th>Select</th>
                    <th>Title</th>
                    <th>Type</th>
                    <th>Category</th>
                    <th>Language</th>
                    <th>Published At</th>
                  </tr>
                </thead>
                <tbody>
                  {recentContent.length === 0 ? (
                    <tr>
                      <td colSpan={6} style={{ textAlign: 'center', padding: '40px' }}>
                        No content published in the selected time range
                      </td>
                    </tr>
                  ) : (
                    recentContent.map((item, index) => (
                      <tr key={`${item.type}-${item._id || index}`}>
                        <td>
                          <input 
                            type="radio" 
                            name="selectedContent"
                            checked={selectedItem === item._id}
                            onChange={() => handleSelectItem(item._id)}
                          />
                        </td>
                        <td>{item.title || item.heading || 'Untitled'}</td>
                        <td>
                          <span className={
                            item.type === 'News' ? styles.statusSent :
                            item.type === 'Story' ? styles.statusScheduled :
                            styles.statusDraft
                          }>
                            {item.type}
                          </span>
                        </td>
                        <td>{item.category?.name || 'N/A'}</td>
                        <td>{getLanguages(item)}</td>
                        <td>{formatDateTime(item.publishedAt)}</td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
