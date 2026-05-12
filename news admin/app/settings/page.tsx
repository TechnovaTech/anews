'use client'

import Sidebar from '@/components/Sidebar'
import { useState, useEffect } from 'react'

export default function SettingsPage() {
  const [showAddForm, setShowAddForm] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [adminUsers, setAdminUsers] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    mobile: '',
    roleName: '',
    modules: {
      news: false,
      stories: false,
      reels: false,
      categories: false,
      users: false,
      notifications: false,
      rewards: false,
      analytics: false,
      ads: false
    }
  })
  const [showPassword, setShowPassword] = useState(false)

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }))
  }

  const handleModuleChange = (module: string, checked: boolean) => {
    setFormData(prev => ({
      ...prev,
      modules: { ...prev.modules, [module]: checked }
    }))
  }

  useEffect(() => {
    fetchAdminUsers()
  }, [])

  const fetchAdminUsers = async () => {
    try {
      setLoading(true)
      const response = await fetch('/api/admin-users')
      if (response.ok) {
        const users = await response.json()
        setAdminUsers(users)
      }
    } catch (error) {
      console.error('Error fetching admin users:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSubmit = async () => {
    try {
      const method = editingId ? 'PUT' : 'POST'
      const url = editingId ? `/api/admin-users/${editingId}` : '/api/admin-users'
      
      const response = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      })

      if (response.ok) {
        await fetchAdminUsers()
        setShowAddForm(false)
        setEditingId(null)
        resetForm()
      }
    } catch (error) {
      console.error('Error saving admin user:', error)
    }
  }

  const resetForm = () => {
    setFormData({
      name: '',
      email: '',
      password: '',
      mobile: '',
      roleName: '',
      modules: {
        news: false,
        stories: false,
        reels: false,
        categories: false,
        users: false,
        notifications: false,
        rewards: false,
        analytics: false,
        ads: false
      }
    })
    setShowPassword(false)
  }

  const handleEdit = (user: any) => {
    setFormData({
      name: user.name,
      email: user.email,
      password: '',
      mobile: user.mobile,
      roleName: user.roleName,
      modules: user.modules
    })
    setEditingId(user._id)
    setShowAddForm(true)
  }

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure you want to delete this admin user?')) {
      try {
        const response = await fetch(`/api/admin-users/${id}`, {
          method: 'DELETE'
        })
        
        if (response.ok) {
          await fetchAdminUsers()
        }
      } catch (error) {
        console.error('Error deleting admin user:', error)
      }
    }
  }

  const getModulesList = (modules: any) => {
    return Object.entries(modules)
      .filter(([_, enabled]) => enabled)
      .map(([module, _]) => module.charAt(0).toUpperCase() + module.slice(1))
      .join(', ') || 'None'
  }

  return (
    <div style={styles.container}>
      <Sidebar />
      <div style={styles.main}>
        <h1 style={styles.title}>Admin User Management</h1>

        <div style={styles.content}>
          <div style={styles.header}>
            <h2 style={styles.subtitle}>Add New Admin User</h2>
            <button 
              style={styles.addBtn} 
              onClick={() => setShowAddForm(!showAddForm)}
            >
              {showAddForm ? 'Cancel' : 'Add New Admin'}
            </button>
          </div>

          {showAddForm && (
            <div style={styles.form}>
              <div style={styles.formGrid}>
                <div style={styles.field}>
                  <label style={styles.label}>Name *</label>
                  <input 
                    type="text" 
                    style={styles.input}
                    value={formData.name}
                    onChange={(e) => handleInputChange('name', e.target.value)}
                    placeholder="Enter admin name"
                  />
                </div>

                <div style={styles.field}>
                  <label style={styles.label}>Email *</label>
                  <input 
                    type="email" 
                    style={styles.input}
                    value={formData.email}
                    onChange={(e) => handleInputChange('email', e.target.value)}
                    placeholder="Enter email address"
                  />
                </div>

                <div style={styles.field}>
                  <label style={styles.label}>Password {editingId ? '(Leave blank to keep current)' : '*'}</label>
                  <div style={styles.passwordContainer}>
                    <input 
                      type={showPassword ? 'text' : 'password'} 
                      style={styles.passwordInput}
                      value={formData.password}
                      onChange={(e) => handleInputChange('password', e.target.value)}
                      placeholder={editingId ? "Leave blank to keep current password" : "Enter password"}
                    />
                    <button
                      type="button"
                      style={styles.eyeButton}
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? '👁️' : '🙈'}
                    </button>
                  </div>
                </div>

                <div style={styles.field}>
                  <label style={styles.label}>Mobile Number *</label>
                  <input 
                    type="tel" 
                    style={styles.input}
                    value={formData.mobile}
                    onChange={(e) => handleInputChange('mobile', e.target.value)}
                    placeholder="Enter mobile number"
                  />
                </div>

                <div style={styles.field}>
                  <label style={styles.label}>Role Name *</label>
                  <input 
                    type="text" 
                    style={styles.input}
                    value={formData.roleName}
                    onChange={(e) => handleInputChange('roleName', e.target.value)}
                    placeholder="e.g., Content Manager, News Editor"
                  />
                </div>
              </div>

              <div style={styles.modulesSection}>
                <label style={styles.label}>Module Access Permissions *</label>
                <div style={styles.moduleGrid}>
                  {Object.entries({
                    news: 'News Management',
                    stories: 'Stories Management', 
                    reels: 'Reels Management',
                    categories: 'Categories Management',
                    users: 'Users Management',
                    notifications: 'Notifications',
                    rewards: 'Rewards Management',
                    analytics: 'Analytics & Reports',
                    ads: 'Ads Management'
                  }).map(([key, label]) => (
                    <label key={key} style={styles.checkboxLabel}>
                      <input
                        type="checkbox"
                        checked={formData.modules[key as keyof typeof formData.modules]}
                        onChange={(e) => handleModuleChange(key, e.target.checked)}
                        style={styles.checkbox}
                      />
                      <span style={styles.checkboxText}>{label}</span>
                    </label>
                  ))}
                </div>
              </div>

              <div style={styles.formButtons}>
                <button style={styles.saveBtn} onClick={handleSubmit}>
                  {editingId ? 'Update Admin User' : 'Create Admin User'}
                </button>
                <button 
                  style={styles.cancelBtn} 
                  onClick={() => {
                    setShowAddForm(false)
                    setEditingId(null)
                    resetForm()
                  }}
                >
                  Cancel
                </button>
              </div>
            </div>
          )}

          <div style={styles.usersList}>
            <h3 style={styles.listTitle}>Admin Users List</h3>
            {loading ? (
              <div style={styles.loading}>Loading admin users...</div>
            ) : (
            <div style={styles.table}>
              <div style={styles.tableHeader}>
                <span style={styles.tableCol}>Name</span>
                <span style={styles.tableCol}>Email</span>
                <span style={styles.tableCol}>Role</span>
                <span style={styles.tableCol}>Modules</span>
                <span style={styles.tableCol}>Status</span>
                <span style={styles.tableCol}>Actions</span>
              </div>
              {adminUsers.map((user) => (
                <div key={user._id} style={styles.tableRow}>
                  <span style={styles.tableCol}>{user.name}</span>
                  <span style={styles.tableCol}>{user.email}</span>
                  <span style={styles.tableCol}>{user.roleName}</span>
                  <span style={styles.tableCol} title={getModulesList(user.modules)}>
                    {getModulesList(user.modules).length > 20 
                      ? getModulesList(user.modules).substring(0, 20) + '...' 
                      : getModulesList(user.modules)
                    }
                  </span>
                  <span style={styles.tableCol}>
                    <span style={styles.statusBadge}>{user.status}</span>
                  </span>
                  <span style={styles.tableCol}>
                    <div style={styles.actionButtons}>
                      <button 
                        style={styles.editBtn} 
                        onClick={() => handleEdit(user)}
                      >
                        Edit
                      </button>
                      <button 
                        style={styles.deleteBtn} 
                        onClick={() => handleDelete(user._id)}
                      >
                        Delete
                      </button>
                    </div>
                  </span>
                </div>
              ))}
            </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

const styles = {
  container: {
    display: 'flex',
    fontFamily: 'Arial, sans-serif',
    backgroundColor: '#f5f5f5',
    minHeight: '100vh',
  },
  main: {
    marginLeft: '250px',
    flex: 1,
    padding: '30px',
  },
  title: {
    fontSize: '28px',
    fontWeight: '700' as const,
    marginBottom: '30px',
    color: '#1f2937',
  },
  content: {
    backgroundColor: 'white',
    padding: '30px',
    borderRadius: '12px',
    boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '30px',
  },
  subtitle: {
    fontSize: '20px',
    fontWeight: '600' as const,
    color: '#374151',
    margin: 0,
  },
  form: {
    backgroundColor: '#f9fafb',
    padding: '25px',
    borderRadius: '8px',
    border: '1px solid #e5e7eb',
  },
  formGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
    gap: '20px',
    marginBottom: '25px',
  },
  field: {
    display: 'flex',
    flexDirection: 'column' as const,
  },
  label: {
    fontSize: '14px',
    fontWeight: '600' as const,
    marginBottom: '6px',
    color: '#374151',
  },
  input: {
    padding: '12px',
    border: '1px solid #d1d5db',
    borderRadius: '6px',
    fontSize: '14px',
    backgroundColor: 'white',
  },
  passwordContainer: {
    position: 'relative' as const,
    display: 'flex',
    alignItems: 'center',
  },
  passwordInput: {
    padding: '12px 45px 12px 12px',
    border: '1px solid #d1d5db',
    borderRadius: '6px',
    fontSize: '14px',
    backgroundColor: 'white',
    width: '100%',
  },
  eyeButton: {
    position: 'absolute' as const,
    right: '12px',
    background: 'none',
    border: 'none',
    cursor: 'pointer',
    fontSize: '16px',
    padding: '4px',
  },
  modulesSection: {
    marginBottom: '25px',
  },
  moduleGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
    gap: '12px',
    marginTop: '10px',
  },
  checkboxLabel: {
    display: 'flex',
    alignItems: 'center',
    cursor: 'pointer',
    padding: '8px',
    backgroundColor: 'white',
    borderRadius: '6px',
    border: '1px solid #e5e7eb',
  },
  checkbox: {
    marginRight: '8px',
    width: '16px',
    height: '16px',
  },
  checkboxText: {
    fontSize: '14px',
    color: '#374151',
  },
  formButtons: {
    display: 'flex',
    gap: '15px',
    justifyContent: 'flex-end',
  },
  addBtn: {
    backgroundColor: '#e31e3a',
    color: 'white',
    padding: '10px 20px',
    border: 'none',
    borderRadius: '6px',
    fontSize: '14px',
    fontWeight: '600' as const,
    cursor: 'pointer',
  },
  saveBtn: {
    backgroundColor: '#10b981',
    color: 'white',
    padding: '12px 24px',
    border: 'none',
    borderRadius: '6px',
    fontSize: '14px',
    fontWeight: '600' as const,
    cursor: 'pointer',
  },
  cancelBtn: {
    backgroundColor: '#6b7280',
    color: 'white',
    padding: '12px 24px',
    border: 'none',
    borderRadius: '6px',
    fontSize: '14px',
    fontWeight: '600' as const,
    cursor: 'pointer',
  },
  usersList: {
    marginTop: '40px',
  },
  listTitle: {
    fontSize: '18px',
    fontWeight: '600' as const,
    marginBottom: '20px',
    color: '#374151',
  },
  table: {
    border: '1px solid #e5e7eb',
    borderRadius: '8px',
    overflow: 'hidden',
    backgroundColor: 'white',
  },
  tableHeader: {
    display: 'grid',
    gridTemplateColumns: '1fr 1.5fr 1fr 1.2fr 0.8fr 1fr',
    padding: '15px',
    backgroundColor: '#f9fafb',
    fontWeight: '600' as const,
    fontSize: '14px',
    borderBottom: '1px solid #e5e7eb',
  },
  tableRow: {
    display: 'grid',
    gridTemplateColumns: '1fr 1.5fr 1fr 1.2fr 0.8fr 1fr',
    padding: '15px',
    borderBottom: '1px solid #f3f4f6',
    fontSize: '14px',
    alignItems: 'center',
  },
  tableCol: {
    padding: '0 8px',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap' as const,
  },
  statusBadge: {
    backgroundColor: '#10b981',
    color: 'white',
    padding: '4px 8px',
    borderRadius: '12px',
    fontSize: '12px',
    fontWeight: '500' as const,
  },
  actionButtons: {
    display: 'flex',
    gap: '8px',
  },
  editBtn: {
    backgroundColor: '#3b82f6',
    color: 'white',
    padding: '6px 12px',
    border: 'none',
    borderRadius: '4px',
    fontSize: '12px',
    cursor: 'pointer',
  },
  deleteBtn: {
    backgroundColor: '#ef4444',
    color: 'white',
    padding: '6px 12px',
    border: 'none',
    borderRadius: '4px',
    fontSize: '12px',
    cursor: 'pointer',
  },
  loading: {
    textAlign: 'center' as const,
    padding: '40px',
    color: '#6b7280',
    fontSize: '16px',
  },
}
