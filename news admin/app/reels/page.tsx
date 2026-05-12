'use client'

import Sidebar from '@/components/Sidebar'
import { useState, useEffect } from 'react'
import styles from './page.module.css'

export default function ManageReelsPage() {
  const [reels, setReels] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchReels()
  }, [])

  const fetchReels = async () => {
    try {
      const res = await fetch('/api/reels?status=all')
      const data = await res.json()
      setReels(data.reels || [])
    } catch (err) {
      console.error('Failed to fetch reels:', err)
    } finally {
      setLoading(false)
    }
  }
  const [selected, setSelected] = useState<number[]>([])
  const [showModal, setShowModal] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [formData, setFormData] = useState({
    title: '',
    summary: '',
    fullArticleLink: '',
    category: 'Politics',
    language: 'EN',
    tags: ['Tag1', 'Tag2', 'Tag3'],
    sourceName: '',
    duration: '',
    videoUrl: '',
    thumbnail: '',
    featured: true,
    enableComments: true
  })

  const toggleSelect = (id: number) => {
    setSelected(selected.includes(id) ? selected.filter(s => s !== id) : [...selected, id])
  }

  const handleEdit = (reel: any) => {
    window.location.href = `/reels/edit/${reel._id}`
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this reel?')) return
    
    try {
      const res = await fetch(`/api/reels/${id}`, { method: 'DELETE' })
      if (res.ok) {
        setReels(reels.filter(r => r._id !== id))
        alert('Reel deleted successfully')
      } else {
        alert('Failed to delete reel')
      }
    } catch (err) {
      console.error('Delete error:', err)
      alert('Error deleting reel')
    }
  }

  const handleBulkDelete = async () => {
    if (selected.length === 0) {
      alert('Please select reels to delete')
      return
    }
    if (!confirm(`Delete ${selected.length} reel(s)?`)) return

    try {
      await Promise.all(selected.map(id => fetch(`/api/reels/${id}`, { method: 'DELETE' })))
      setReels(reels.filter(r => !selected.includes(r._id)))
      setSelected([])
      alert('Reels deleted successfully')
    } catch (err) {
      console.error('Bulk delete error:', err)
      alert('Error deleting reels')
    }
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
  }

  const handleToggle = (field: 'featured' | 'enableComments') => {
    setFormData(prev => ({ ...prev, [field]: !prev[field] }))
  }

  const handleSubmit = () => {
    if (editingId) {
      setReels(reels.map(reel => reel.id === editingId ? { ...reel, headline: formData.title, category: formData.category, language: formData.language } : reel))
    } else {
      const newReel = {
        id: reels.length + 1,
        headline: formData.title,
        category: formData.category,
        language: formData.language,
        status: 'Draft',
        views: 0,
        likes: 0,
        dateCreated: new Date().toISOString().split('T')[0]
      }
      setReels([...reels, newReel])
    }
    setShowModal(false)
    setEditingId(null)
    setFormData({
      title: '',
      summary: '',
      fullArticleLink: '',
      category: 'Politics',
      language: 'EN',
      tags: ['Tag1', 'Tag2', 'Tag3'],
      sourceName: '',
      duration: '',
      videoUrl: '',
      thumbnail: '',
      featured: true,
      enableComments: true
    })
  }

  return (
    <div className={styles.container}>
      <Sidebar />
      <div className={styles.main}>
        <div className={styles.header}>
          <h1 className={styles.title}>Manage Reels – All Reels</h1>
          <button className={styles.addBtn} onClick={() => window.location.href = '/reels/add'}>+ Add Reel</button>
        </div>

        <div className={styles.filters}>
          <input type="text" placeholder="Search reels by headline or tags..." className={styles.search} />
          <select className={styles.select}><option>Category</option></select>
          <select className={styles.select}><option>Language</option></select>
          <select className={styles.select}><option>Status</option></select>
        </div>

        <div className={styles.content}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th></th>
                <th>Reel Headline</th>
                <th>Category</th>
                <th>Language</th>
                <th>Status</th>
                <th>Views Count</th>
                <th>Likes Count</th>
                <th>Date Created</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={9} style={{ textAlign: 'center' }}>Loading...</td></tr>
              ) : reels.length === 0 ? (
                <tr><td colSpan={9} style={{ textAlign: 'center' }}>No reels found</td></tr>
              ) : (
                reels.map(reel => (
                  <tr key={reel._id}>
                    <td><input type="checkbox" checked={selected.includes(reel._id)} onChange={() => toggleSelect(reel._id)} /></td>
                    <td><a href="#" className={styles.link}>{reel.title}</a></td>
                    <td><span className={styles.badge}>{reel.category?.name || 'N/A'}</span></td>
                    <td>{reel.language || 'EN'}</td>
                    <td>
                      <span className={reel.status === 'published' ? styles.statusPublished : styles.statusDraft}>
                        {reel.status}
                      </span>
                    </td>
                    <td>{reel.views || 0}</td>
                    <td>{reel.likes || 0}</td>
                    <td>{new Date(reel.createdAt).toLocaleDateString()}</td>
                    <td>
                      <button className={styles.iconBtn} onClick={() => handleEdit(reel)}>✏️</button>
                      <button className={styles.iconBtn} onClick={() => window.location.href = `/reels/view/${reel._id}`}>👁️</button>
                      <button className={styles.iconBtn} onClick={() => handleDelete(reel._id)}>🗑️</button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className={styles.bulkActions}>
          <button className={styles.publishBtn}>Publish</button>
          <button className={styles.unpublishBtn}>Unpublish</button>
          <button className={styles.deleteBtn} onClick={handleBulkDelete}>Delete</button>
        </div>

        {showModal && (
          <div className={styles.modal}>
            <div className={styles.modalContentLarge}>
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
                      <option value="Politics">Politics</option>
                      <option value="Entertainment">Entertainment</option>
                      <option value="Finance">Finance</option>
                      <option value="Sports">Sports</option>
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
                    <label className={styles.label}>Current Video</label>
                    <div className={styles.videoPreview}>
                      {formData.videoUrl ? (
                        <video src={formData.videoUrl} controls style={{ width: '100%', height: '100%' }} />
                      ) : (
                        <div className={styles.previewPlaceholder}>No Video</div>
                      )}
                    </div>
                    <input
                      type="text"
                      name="videoUrl"
                      value={formData.videoUrl}
                      onChange={handleChange}
                      placeholder="Video URL"
                      className={styles.input}
                      style={{ marginTop: '8px' }}
                    />
                  </div>

                  <div className={styles.formGroup}>
                    <label className={styles.label}>Current Thumbnail</label>
                    <div className={styles.thumbnailPreview}>
                      {formData.thumbnail ? (
                        <img src={formData.thumbnail} alt="Thumbnail" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                      ) : (
                        <div className={styles.previewPlaceholder}>No Thumbnail</div>
                      )}
                    </div>
                    <input
                      type="text"
                      name="thumbnail"
                      value={formData.thumbnail}
                      onChange={handleChange}
                      placeholder="Thumbnail URL"
                      className={styles.input}
                      style={{ marginTop: '8px' }}
                    />
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
                    <div className={styles.toggleGroupInline}>
                      <label className={styles.label}>Featured/Breaking</label>
                      <div 
                        className={`${styles.toggle} ${formData.featured ? styles.toggleActive : ''}`}
                        onClick={() => handleToggle('featured')}
                      >
                        <div className={styles.toggleCircle}></div>
                      </div>
                    </div>

                    <div className={styles.toggleGroupInline}>
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
                <button onClick={() => { setShowModal(false); setEditingId(null); }} className={styles.cancelBtnLarge}>Cancel</button>
                <button onClick={handleSubmit} className={styles.updateBtnLarge}>Update</button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
