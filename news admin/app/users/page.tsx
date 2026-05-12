'use client'

import Sidebar from '@/components/Sidebar'
import { useState, useEffect } from 'react'
import styles from './page.module.css'

export default function UsersPage() {
  const [users, setUsers] = useState<any[]>([])
  const [filteredUsers, setFilteredUsers] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [selected, setSelected] = useState<string[]>([])
  const [searchTerm, setSearchTerm] = useState('')
  const [roleFilter, setRoleFilter] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [stateFilter, setStateFilter] = useState('')
  const [viewUser, setViewUser] = useState<any>(null)

  useEffect(() => {
    fetchUsers()
  }, [])

  useEffect(() => {
    let filtered = users

    if (searchTerm) {
      filtered = filtered.filter(u => 
        u.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.phone?.toLowerCase().includes(searchTerm.toLowerCase())
      )
    }

    if (roleFilter) {
      filtered = filtered.filter(u => u.role === roleFilter)
    }

    if (statusFilter) {
      if (statusFilter === 'active') {
        filtered = filtered.filter(u => u.isActive === true)
      } else if (statusFilter === 'inactive') {
        filtered = filtered.filter(u => u.isActive === false)
      }
    }

    if (stateFilter) {
      filtered = filtered.filter(u => u.state === stateFilter)
    }

    setFilteredUsers(filtered)
  }, [users, searchTerm, roleFilter, statusFilter, stateFilter])

  const fetchUsers = async () => {
    try {
      const res = await fetch('/api/users')
      const data = await res.json()
      setUsers(data.users || [])
      setFilteredUsers(data.users || [])
      setLoading(false)
    } catch (error) {
      console.error('Failed to fetch users:', error)
      setLoading(false)
    }
  }

  const toggleSelect = (id: string) => {
    setSelected(selected.includes(id) ? selected.filter(s => s !== id) : [...selected, id])
  }

  const toggleSelectAll = () => {
    setSelected(selected.length === filteredUsers.length ? [] : filteredUsers.map(u => u._id))
  }

  const handleBlock = async () => {
    if (selected.length === 0) return alert('Please select users to block')
    try {
      for (const id of selected) {
        await fetch(`/api/users/${id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ isActive: false })
        })
      }
      alert(`${selected.length} user(s) blocked successfully!`)
      setSelected([])
      fetchUsers()
    } catch (error) {
      alert('Failed to block users')
    }
  }

  const handleUnblock = async () => {
    if (selected.length === 0) return alert('Please select users to unblock')
    try {
      for (const id of selected) {
        await fetch(`/api/users/${id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ isActive: true })
        })
      }
      alert(`${selected.length} user(s) unblocked successfully!`)
      setSelected([])
      fetchUsers()
    } catch (error) {
      alert('Failed to unblock users')
    }
  }

  const handleDelete = async () => {
    if (selected.length === 0) return alert('Please select users to delete')
    if (!confirm(`Are you sure you want to delete ${selected.length} user(s)? This action cannot be undone.`)) return
    try {
      for (const id of selected) {
        await fetch(`/api/users/${id}`, { method: 'DELETE' })
      }
      alert(`${selected.length} user(s) deleted successfully!`)
      setSelected([])
      fetchUsers()
    } catch (error) {
      alert('Failed to delete users')
    }
  }

  const handleExport = () => {
    const csv = ['Name,Email,Phone,State,Role,Status,Wallet Balance,Date Registered']
    filteredUsers.forEach(u => {
      csv.push(`${u.name},${u.email},${u.phone || ''},${u.state || ''},${u.role},${u.isActive ? 'Active' : 'Inactive'},${u.walletBalance || 0},${new Date(u.createdAt).toLocaleDateString()}`)
    })
    const blob = new Blob([csv.join('\n')], { type: 'text/csv' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `users_export_${new Date().toISOString().split('T')[0]}.csv`
    a.click()
  }

  const toggleUserStatus = async (id: string, currentStatus: boolean) => {
    try {
      const res = await fetch(`/api/users/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isActive: !currentStatus })
      })
      if (res.ok) {
        alert(`User ${!currentStatus ? 'unblocked' : 'blocked'} successfully!`)
        fetchUsers()
      }
    } catch (error) {
      alert('Failed to update user status')
    }
  }

  const deleteUser = async (id: string) => {
    if (!confirm('Are you sure you want to delete this user? This action cannot be undone.')) return
    try {
      const res = await fetch(`/api/users/${id}`, { method: 'DELETE' })
      if (res.ok) {
        alert('User deleted successfully!')
        fetchUsers()
      } else {
        alert('Failed to delete user')
      }
    } catch (error) {
      alert('Failed to delete user')
    }
  }

  if (loading) {
    return (
      <div className={styles.container}>
        <Sidebar />
        <div className={styles.main}>
          <div style={{ textAlign: 'center', padding: '50px' }}>Loading users...</div>
        </div>
      </div>
    )
  }

  return (
    <div className={styles.container}>
      <Sidebar />
      <div className={styles.main}>
        <div className={styles.header}>
          <h1 className={styles.title}>Manage Users</h1>
          <button className={styles.addBtn}>+ Add User</button>
        </div>

        <div className={styles.filters}>
          <input 
            type="text" 
            placeholder="Search by name, email, or phone..." 
            className={styles.search} 
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
          <select className={styles.select} value={roleFilter} onChange={(e) => setRoleFilter(e.target.value)}>
            <option value="">All Roles</option>
            <option value="admin">Admin</option>
            <option value="user">User</option>
            <option value="editor">Editor</option>
          </select>
          <select className={styles.select} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
            <option value="">All Status</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
          <select className={styles.select} value={stateFilter} onChange={(e) => setStateFilter(e.target.value)}>
            <option value="">All States</option>
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
            <option value="Delhi">Delhi</option>
          </select>
        </div>

        <div className={styles.bulkActions}>
          <button className={styles.blockBtn} onClick={handleBlock}>Block Users</button>
          <button className={styles.unblockBtn} onClick={handleUnblock}>Unblock Users</button>
          <button className={styles.deleteBtn} onClick={handleDelete}>Delete Users</button>
          <button className={styles.exportBtn} onClick={handleExport}>USER EXPORT</button>
        </div>

        <div className={styles.content}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th><input type="checkbox" checked={selected.length === filteredUsers.length && filteredUsers.length > 0} onChange={toggleSelectAll} /></th>
                <th>Name</th>
                <th>Email/Phone</th>
                <th>State</th>
                <th>Role</th>
                <th>Status</th>
                <th>Date Registered</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={8} style={{ textAlign: 'center', padding: '20px' }}>No users found</td>
                </tr>
              ) : (
                filteredUsers.map(user => (
                  <tr key={user._id}>
                    <td><input type="checkbox" checked={selected.includes(user._id)} onChange={() => toggleSelect(user._id)} /></td>
                    <td>{user.name}</td>
                    <td>{user.email}</td>
                    <td>{user.state || 'N/A'}</td>
                    <td>
                      <span className={user.role === 'admin' ? styles.roleAdmin : user.role === 'user' ? styles.roleUser : styles.roleModerator}>
                        {user.role}
                      </span>
                    </td>
                    <td>
                      <span className={user.isActive ? styles.statusActive : styles.statusInactive}>
                        {user.isActive ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td>{new Date(user.createdAt).toLocaleDateString()}</td>
                    <td>
                      <button className={styles.iconBtn} onClick={() => setViewUser(user)} title="View">👁</button>
                      <button className={styles.iconBtn} onClick={() => window.location.href = `/users/edit/${user._id}`} title="Edit">✏️</button>
                      <button className={styles.iconBtn} onClick={() => toggleUserStatus(user._id, user.isActive)} title={user.isActive ? 'Block' : 'Unblock'}>🔒</button>
                      <button className={styles.iconBtn} onClick={() => deleteUser(user._id)} title="Delete">🗑️</button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {viewUser && (
          <div className={styles.modal} onClick={() => setViewUser(null)}>
            <div className={styles.modalContent} onClick={(e) => e.stopPropagation()}>
              <div className={styles.modalHeader}>
                <h2>User Details</h2>
                <button className={styles.closeBtn} onClick={() => setViewUser(null)}>×</button>
              </div>
              <div className={styles.modalBody}>
                <div className={styles.detailRow}>
                  <strong>Name:</strong> <span>{viewUser.name}</span>
                </div>
                <div className={styles.detailRow}>
                  <strong>Email:</strong> <span>{viewUser.email}</span>
                </div>
                <div className={styles.detailRow}>
                  <strong>Phone:</strong> <span>{viewUser.phone || 'N/A'}</span>
                </div>
                <div className={styles.detailRow}>
                  <strong>Role:</strong> <span className={viewUser.role === 'admin' ? styles.roleAdmin : styles.roleUser}>{viewUser.role}</span>
                </div>
                <div className={styles.detailRow}>
                  <strong>Status:</strong> <span className={viewUser.isActive ? styles.statusActive : styles.statusInactive}>{viewUser.isActive ? 'Active' : 'Inactive'}</span>
                </div>
                <div className={styles.detailRow}>
                  <strong>State:</strong> <span>{viewUser.state || 'Not specified'}</span>
                </div>
                <div className={styles.detailRow}>
                  <strong>Language:</strong> <span>{viewUser.preferences?.language || 'EN'}</span>
                </div>
                <div className={styles.detailRow}>
                  <strong>Wallet Balance:</strong> <span>₹{viewUser.walletBalance || 0}</span>
                </div>
                <div className={styles.detailRow}>
                  <strong>Date Registered:</strong> <span>{new Date(viewUser.createdAt).toLocaleString()}</span>
                </div>
                <div className={styles.detailRow}>
                  <strong>Last Updated:</strong> <span>{new Date(viewUser.updatedAt).toLocaleString()}</span>
                </div>
              </div>
              <div className={styles.modalFooter}>
                <button className={styles.editBtn} onClick={() => window.location.href = `/users/edit/${viewUser._id}`}>Edit User</button>
                <button className={styles.cancelBtn} onClick={() => setViewUser(null)}>Close</button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
