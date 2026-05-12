'use client'

import Sidebar from '@/components/Sidebar'
import { useState, useEffect } from 'react'
import styles from './page.module.css'

export default function CategoriesPage() {
  const [categories, setCategories] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [formData, setFormData] = useState({ name: '', labels: { english: '', hindi: '', bengali: '' }, isActive: true })

  useEffect(() => {
    fetchCategories()
  }, [])

  const fetchCategories = async () => {
    try {
      const res = await fetch('/api/categories')
      const data = await res.json()
      setCategories(data.categories || [])
      setLoading(false)
    } catch (error) {
      console.error('Failed to fetch categories:', error)
      setLoading(false)
    }
  }

  const toggleVisibility = async (id: string, currentStatus: boolean) => {
    try {
      const res = await fetch(`/api/categories/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isActive: !currentStatus })
      })
      if (res.ok) {
        fetchCategories()
      }
    } catch (error) {
      alert('Failed to update visibility')
    }
  }

  const handleEdit = (cat: any) => {
    setEditingId(cat._id)
    setFormData({ 
      name: cat.name, 
      labels: cat.labels || { english: '', hindi: '', bengali: '' }, 
      isActive: cat.isActive 
    })
    setShowModal(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this category?')) return
    try {
      const res = await fetch(`/api/categories/${id}`, { method: 'DELETE' })
      if (res.ok) {
        alert('Category deleted successfully!')
        fetchCategories()
      }
    } catch (error) {
      alert('Failed to delete category')
    }
  }

  const handleSubmit = async () => {
    if (!formData.name) return alert('Category name is required')
    if (!formData.labels.english) return alert('English label is required')
    
    const slug = formData.name.toLowerCase().replace(/\s+/g, '-')
    const payload = { 
      name: formData.name,
      slug,
      description: formData.labels.english,
      labels: {
        english: formData.labels.english,
        hindi: formData.labels.hindi,
        bengali: formData.labels.bengali
      },
      isActive: formData.isActive,
      updatedAt: new Date()
    }

    console.log('Sending payload:', payload)

    try {
      if (editingId) {
        const res = await fetch(`/api/categories/${editingId}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        })
        const result = await res.json()
        console.log('Update result:', result)
        if (res.ok) {
          alert('Category updated successfully!')
        } else {
          alert('Error: ' + (result.error || 'Failed to update'))
        }
      } else {
        const res = await fetch('/api/categories', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        })
        const result = await res.json()
        console.log('Create result:', result)
        if (res.ok) {
          alert('Category created successfully!')
        } else {
          alert('Error: ' + (result.error || 'Failed to create'))
        }
      }
      setShowModal(false)
      setEditingId(null)
      setFormData({ name: '', labels: { english: '', hindi: '', bengali: '' }, isActive: true })
      fetchCategories()
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to save category: ' + error)
    }
  }

  if (loading) {
    return (
      <div className={styles.container}>
        <Sidebar />
        <div className={styles.main}>
          <div style={{ textAlign: 'center', padding: '50px' }}>Loading categories...</div>
        </div>
      </div>
    )
  }

  return (
    <div className={styles.container}>
      <Sidebar />
      <div className={styles.main}>
        <div className={styles.header}>
          <h1 className={styles.title}>Manage Categories</h1>
          <button className={styles.addBtn} onClick={() => { setShowModal(true); setEditingId(null); setFormData({ name: '', labels: { english: '', hindi: '', bengali: '' }, isActive: true }); }}>+ Add Category</button>
        </div>

        <div className={styles.content}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Category Name</th>
                <th>Language Labels</th>
                <th>Status</th>
                <th>Visibility</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {categories.length === 0 ? (
                <tr>
                  <td colSpan={5} style={{ textAlign: 'center', padding: '20px' }}>No categories found</td>
                </tr>
              ) : (
                categories.map(cat => (
                  <tr key={cat._id}>
                    <td>{cat.name}</td>
                    <td>
                      {cat.labels ? (
                        <>
                          <strong>EN:</strong> {cat.labels.english || 'N/A'}, 
                          <strong>HI:</strong> {cat.labels.hindi || 'N/A'}, 
                          <strong>BN:</strong> {cat.labels.bengali || 'N/A'}
                        </>
                      ) : 'N/A'}
                    </td>
                    <td>
                      <span className={cat.isActive ? styles.statusActive : styles.statusInactive}>
                        {cat.isActive ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td>
                      <label className={styles.toggle}>
                        <input type="checkbox" checked={cat.isActive} onChange={() => toggleVisibility(cat._id, cat.isActive)} />
                        <span className={styles.slider}></span>
                      </label>
                    </td>
                    <td>
                      <button className={styles.iconBtn} onClick={() => handleEdit(cat)} title="Edit">✏️</button>
                      <button className={styles.iconBtn} onClick={() => handleDelete(cat._id)} title="Delete">🗑️</button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {showModal && (
          <div className={styles.modal} onClick={() => setShowModal(false)}>
            <div className={styles.modalContent} onClick={(e) => e.stopPropagation()}>
              <h2 className={styles.modalTitle}>{editingId ? 'Edit Category' : 'Add New Category'}</h2>
              <div className={styles.formGroup}>
                <label>Category Name *</label>
                <input value={formData.name} onChange={async (e) => {
                  const newName = e.target.value;
                  setFormData({...formData, name: newName, labels: {...formData.labels, english: newName}});
                  
                  if (newName.trim()) {
                    try {
                      const hindiRes = await fetch('/api/translate', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ text: newName, targetLang: 'hi' })
                      });
                      const hindiData = await hindiRes.json();
                      
                      const bengaliRes = await fetch('/api/translate', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ text: newName, targetLang: 'bn' })
                      });
                      const bengaliData = await bengaliRes.json();
                      
                      setFormData(prev => ({
                        ...prev,
                        labels: {
                          english: newName,
                          hindi: hindiData.translatedText || newName,
                          bengali: bengaliData.translatedText || newName
                        }
                      }));
                    } catch (error) {
                      console.error('Translation failed:', error);
                    }
                  }
                }} placeholder="e.g., Politics, Sports" />
              </div>
              <div className={styles.formGroup}>
                <label>Language Labels *</label>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  <input 
                    value={formData.labels.english} 
                    onChange={(e) => setFormData({...formData, labels: {...formData.labels, english: e.target.value}})} 
                    placeholder="English: Politics" 
                  />
                  <input 
                    value={formData.labels.hindi} 
                    onChange={(e) => setFormData({...formData, labels: {...formData.labels, hindi: e.target.value}})} 
                    placeholder="Hindi: राजनीति" 
                  />
                  <input 
                    value={formData.labels.bengali} 
                    onChange={(e) => setFormData({...formData, labels: {...formData.labels, bengali: e.target.value}})} 
                    placeholder="Bengali: রাজনীতি" 
                  />
                </div>
              </div>
              <div className={styles.modalButtons}>
                <button className={styles.cancelBtn} onClick={() => { setShowModal(false); setEditingId(null); }}>Cancel</button>
                <button className={styles.saveBtn} onClick={handleSubmit}>{editingId ? 'Update Category' : 'Save Category'}</button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
