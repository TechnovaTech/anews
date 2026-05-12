'use client'

import React, { useState, useEffect } from 'react'
import Sidebar from '@/components/Sidebar'
import { useRouter } from 'next/navigation'
import styles from './page.module.css'

export default function EditUserPage({ params }: any) {
  const router = useRouter()
  const [userId, setUserId] = useState<string | null>(null)
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    role: 'user',
    isActive: true,
    state: '',
    dateRegistered: ''
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const initParams = async () => {
      const resolvedParams = await params
      setUserId(resolvedParams.id)
    }
    initParams()
  }, [params])

  useEffect(() => {
    if (!userId) return

    const fetchUser = async () => {
      try {
        const res = await fetch(`/api/users/${userId}`)
        const data = await res.json()
        
        if (res.ok && data.user) {
          setFormData({
            name: data.user.name || '',
            email: data.user.email || '',
            phone: data.user.phone || '',
            role: data.user.role || 'user',
            isActive: data.user.isActive !== false,
            state: data.user.state || '',
            dateRegistered: data.user.createdAt ? new Date(data.user.createdAt).toISOString().split('T')[0] : ''
          })
        }
      } catch (error) {
        console.error('Failed to fetch user:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchUser()
  }, [userId])

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
  }

  const handleToggle = () => {
    setFormData(prev => ({ ...prev, isActive: !prev.isActive }))
  }

  const handleSave = async () => {
    if (!userId) return

    try {
      const res = await fetch(`/api/users/${userId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: formData.name,
          email: formData.email,
          phone: formData.phone,
          role: formData.role,
          isActive: formData.isActive,
          state: formData.state
        })
      })

      if (res.ok) {
        alert('User updated successfully!')
        router.push('/users')
      } else {
        alert('Failed to update user')
      }
    } catch (error) {
      console.error('Error updating user:', error)
    }
  }

  if (loading) {
    return (
      <div className={styles.container}>
        <Sidebar />
        <div className={styles.main}>
          <h1 className={styles.title}>Loading...</h1>
        </div>
      </div>
    )
  }

  return (
    <div className={styles.container}>
      <Sidebar />
      <div className={styles.main}>
        <h1 className={styles.title}>User Profile & Edit</h1>

        <div className={styles.content}>
          <div className={styles.formRow}>
            <div className={styles.formGroup}>
              <label className={styles.label}>Name</label>
              <input
                type="text"
                name="name"
                value={formData.name}
                onChange={handleChange}
                className={styles.input}
              />
            </div>

            <div className={styles.formGroup}>
              <label className={styles.label}>Email</label>
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                className={styles.input}
              />
            </div>

            <div className={styles.formGroup}>
              <label className={styles.label}>Phone</label>
              <input
                type="text"
                name="phone"
                value={formData.phone}
                onChange={handleChange}
                className={styles.input}
              />
            </div>
          </div>

          <div className={styles.formRow}>
            <div className={styles.formGroup}>
              <label className={styles.label}>Role</label>
              <select
                name="role"
                value={formData.role}
                onChange={handleChange}
                className={styles.select}
              >
                <option value="user">User</option>
                <option value="admin">Admin</option>
                <option value="editor">Editor</option>
              </select>
            </div>

            <div className={styles.formGroup}>
              <label className={styles.label}>Status</label>
              <div 
                className={`${styles.toggle} ${formData.isActive ? styles.toggleActive : ''}`}
                onClick={handleToggle}
              >
                <div className={styles.toggleCircle}></div>
              </div>
            </div>

            <div className={styles.formGroup}>
              <label className={styles.label}>State</label>
              <select
                name="state"
                value={formData.state}
                onChange={handleChange}
                className={styles.select}
              >
                <option value="">Select State</option>
                <option value="Andhra Pradesh">Andhra Pradesh</option>
                <option value="Arunachal Pradesh">Arunachal Pradesh</option>
                <option value="Assam">Assam</option>
                <option value="Bihar">Bihar</option>
                <option value="Chhattisgarh">Chhattisgarh</option>
                <option value="Goa">Goa</option>
                <option value="Gujarat">Gujarat</option>
                <option value="Haryana">Haryana</option>
                <option value="Himachal Pradesh">Himachal Pradesh</option>
                <option value="Jharkhand">Jharkhand</option>
                <option value="Karnataka">Karnataka</option>
                <option value="Kerala">Kerala</option>
                <option value="Madhya Pradesh">Madhya Pradesh</option>
                <option value="Maharashtra">Maharashtra</option>
                <option value="Manipur">Manipur</option>
                <option value="Meghalaya">Meghalaya</option>
                <option value="Mizoram">Mizoram</option>
                <option value="Nagaland">Nagaland</option>
                <option value="Odisha">Odisha</option>
                <option value="Punjab">Punjab</option>
                <option value="Rajasthan">Rajasthan</option>
                <option value="Sikkim">Sikkim</option>
                <option value="Tamil Nadu">Tamil Nadu</option>
                <option value="Telangana">Telangana</option>
                <option value="Tripura">Tripura</option>
                <option value="Uttar Pradesh">Uttar Pradesh</option>
                <option value="Uttarakhand">Uttarakhand</option>
                <option value="West Bengal">West Bengal</option>
                <option value="Andaman and Nicobar Islands">Andaman and Nicobar Islands</option>
                <option value="Chandigarh">Chandigarh</option>
                <option value="Dadra & Nagar Haveli and Daman & Diu">Dadra & Nagar Haveli and Daman & Diu</option>
                <option value="Delhi (NCT of Delhi)">Delhi (NCT of Delhi)</option>
                <option value="Jammu & Kashmir">Jammu & Kashmir</option>
                <option value="Ladakh">Ladakh</option>
                <option value="Lakshadweep">Lakshadweep</option>
                <option value="Puducherry">Puducherry</option>
              </select>
            </div>

            <div className={styles.formGroup}>
              <label className={styles.label}>Date Registered</label>
              <input
                type="text"
                name="dateRegistered"
                value={formData.dateRegistered}
                onChange={handleChange}
                className={styles.input}
                readOnly
              />
            </div>
          </div>
        </div>

        <div className={styles.loginHistory}>
          <h2 className={styles.sectionTitle}>Login History</h2>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Timestamp</th>
                <th>Device</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>2023-10-10 10:00 AM</td>
                <td>Chrome on Windows 10</td>
              </tr>
              <tr>
                <td>2023-09-28 09:45</td>
                <td>Safari on iOS</td>
              </tr>
              <tr>
                <td>2023-09-20 14:30</td>
                <td>Firefox on MacOS</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div className={styles.buttonRow}>
          <button onClick={() => router.push('/users')} className={styles.cancelBtn}>Cancel</button>
          <button onClick={handleSave} className={styles.saveBtn}>Save Changes</button>
        </div>
      </div>
    </div>
  )
}
