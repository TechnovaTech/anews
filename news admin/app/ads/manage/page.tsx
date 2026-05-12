'use client'

import Sidebar from '@/components/Sidebar'
import { useState, useEffect } from 'react'
import Link from 'next/link'
import styles from './page.module.css'

export default function ManageAdvertisementsPage() {
  const [ads, setAds] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('all')

  useEffect(() => {
    fetchAds()
  }, [filter])

  const fetchAds = async () => {
    setLoading(true)
    try {
      const url = filter === 'all' ? '/api/ads' : `/api/ads?status=${filter}`
      const response = await fetch(url)
      const data = await response.json()
      setAds(data.ads || [])
    } catch (error) {
      console.error('Error fetching ads:', error)
    }
    setLoading(false)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this advertisement?')) return
    
    try {
      const response = await fetch(`/api/ads/${id}`, { method: 'DELETE' })
      if (response.ok) {
        alert('Advertisement deleted successfully!')
        fetchAds()
      }
    } catch (error) {
      console.error('Error deleting ad:', error)
      alert('Failed to delete advertisement')
    }
  }

  const handleStatusToggle = async (id: string, currentStatus: string) => {
    const newStatus = currentStatus === 'active' ? 'inactive' : 'active'
    try {
      const response = await fetch(`/api/ads/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus })
      })
      if (response.ok) {
        fetchAds()
      }
    } catch (error) {
      console.error('Error updating status:', error)
    }
  }

  const formatDate = (date: string) => {
    if (!date) return 'N/A'
    return new Date(date).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    })
  }

  return (
    <div className={styles.container}>
      <Sidebar />
      <div className={styles.main}>
        <div className={styles.content}>
          <div className={styles.header}>
            <h1 className={styles.title}>Manage Advertisements</h1>
            <Link href="/ads/add" className={styles.addBtn}>
              + Add New Ad
            </Link>
          </div>

          <div className={styles.filterRow}>
            <select 
              value={filter} 
              onChange={(e) => setFilter(e.target.value)}
              className={styles.select}
            >
              <option value="all">All Ads</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="scheduled">Scheduled</option>
            </select>
          </div>

          {loading ? (
            <div className={styles.loading}>Loading...</div>
          ) : ads.length === 0 ? (
            <div className={styles.empty}>
              <p>No advertisements found</p>
              <Link href="/ads/add" className={styles.addBtn}>
                Add Your First Ad
              </Link>
            </div>
          ) : (
            <table className={styles.table}>
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Position</th>
                  <th>Status</th>
                  <th>Start Date</th>
                  <th>End Date</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {ads.map((ad) => (
                  <tr key={ad._id}>
                    <td>
                      <div className={styles.adTitle}>
                        {ad.imageUrl && (
                          <img src={ad.imageUrl} alt={ad.title} className={styles.thumbnail} />
                        )}
                        <span>{ad.title}</span>
                      </div>
                    </td>
                    <td>
                      <span className={styles.badge}>{ad.position}</span>
                    </td>
                    <td>
                      <span className={
                        ad.status === 'active' ? styles.statusActive :
                        ad.status === 'inactive' ? styles.statusInactive :
                        styles.statusScheduled
                      }>
                        {ad.status}
                      </span>
                    </td>
                    <td>{formatDate(ad.startDate)}</td>
                    <td>{formatDate(ad.endDate)}</td>
                    <td>
                      <div className={styles.actions}>
                        <button
                          onClick={() => handleStatusToggle(ad._id, ad.status)}
                          className={styles.toggleBtn}
                          title={ad.status === 'active' ? 'Deactivate' : 'Activate'}
                        >
                          {ad.status === 'active' ? '⏸' : '▶'}
                        </button>
                        <button
                          onClick={() => handleDelete(ad._id)}
                          className={styles.deleteBtn}
                          title="Delete"
                        >
                          🗑
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  )
}
