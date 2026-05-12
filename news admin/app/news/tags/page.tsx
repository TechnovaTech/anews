'use client'

import Sidebar from '@/components/Sidebar'
import { useState, useEffect } from 'react'
import styles from './page.module.css'

export default function TagsPage() {
  const [tags, setTags] = useState<any[]>([])
  const [showModal, setShowModal] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [formData, setFormData] = useState({ name: '', isActive: true })

  useEffect(() => {
    fetchTags()
  }, [])

  const fetchTags = async () => {
    const res = await fetch('/api/tags')
    const data = await res.json()
    setTags(data)
  }

  const handleEdit = (tag: any) => {
    setEditingId(tag._id)
    setFormData({ name: tag.name, isActive: tag.isActive })
    setShowModal(true)
  }

  const handleDelete = async (id: string) => {
    if (confirm('Delete this tag?')) {
      await fetch(`/api/tags/${id}`, { method: 'DELETE' })
      fetchTags()
    }
  }

  const toggleStatus = async (tag: any) => {
    await fetch(`/api/tags/${tag._id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ isActive: !tag.isActive })
    })
    fetchTags()
  }

  const handleSubmit = async () => {
    if (editingId) {
      await fetch(`/api/tags/${editingId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      })
    } else {
      await fetch('/api/tags', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      })
    }
    setShowModal(false)
    setEditingId(null)
    setFormData({ name: '', isActive: true })
    fetchTags()
  }

  return (
    <div className={styles.container}>
      <Sidebar />
      <div className={styles.main}>
        <div className={styles.header}>
          <h1 className={styles.title}>Manage Tags</h1>
          <button className={styles.addBtn} onClick={() => setShowModal(true)}>+ Add Tag</button>
        </div>

        <div className={styles.content}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Tag Name</th>
                <th>Status</th>
                <th>Date Created</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {tags.map(tag => (
                <tr key={tag._id}>
                  <td>{tag.name}</td>
                  <td>
                    <span 
                      className={tag.isActive ? styles.statusActive : styles.statusInactive}
                      onClick={() => toggleStatus(tag)}
                      style={{ cursor: 'pointer' }}
                    >
                      {tag.isActive ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td>{new Date(tag.createdAt).toLocaleDateString()}</td>
                  <td>
                    <button className={styles.iconBtn} onClick={() => handleEdit(tag)}>✏️</button>
                    <button className={styles.iconBtn} onClick={() => handleDelete(tag._id)}>🗑️</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {showModal && (
          <div className={styles.modal}>
            <div className={styles.modalContent}>
              <h2 className={styles.modalTitle}>{editingId ? 'Edit Tag' : 'Add New Tag'}</h2>
              <div className={styles.formGroup}>
                <label>Tag Name</label>
                <input value={formData.name} onChange={(e) => setFormData({...formData, name: e.target.value})} />
              </div>
              <div className={styles.formGroup}>
                <label>Status</label>
                <select value={formData.isActive ? 'Active' : 'Inactive'} onChange={(e) => setFormData({...formData, isActive: e.target.value === 'Active'})}>
                  <option>Active</option>
                  <option>Inactive</option>
                </select>
              </div>
              <div className={styles.modalButtons}>
                <button className={styles.cancelBtn} onClick={() => { setShowModal(false); setEditingId(null); }}>Cancel</button>
                <button className={styles.saveBtn} onClick={handleSubmit}>{editingId ? 'Update Tag' : 'Save Tag'}</button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
