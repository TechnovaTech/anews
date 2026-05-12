'use client'

import Sidebar from '@/components/Sidebar'
import { useState } from 'react'
import styles from './page.module.css'

export default function PastNotificationsPage() {
  const [notifications] = useState([
    { id: 1, title: 'Notification Title 1', audience: 'All Users', status: 'Sent', dateTime: '2023-10-01 10:00 AM', sentBy: 'admin123' },
    { id: 2, title: 'Notification Title 2', audience: 'Category Name', status: 'Scheduled', dateTime: '2023-10-02 11:00 AM', sentBy: 'admin456' },
    { id: 3, title: 'Notification Title 3', audience: 'Language', status: 'Draft', dateTime: '2023-10-03 12:00 PM', sentBy: 'admin789' }
  ])

  return (
    <div className={styles.container}>
      <Sidebar />
      <div className={styles.main}>
        <div className={styles.header}>
          <h1 className={styles.title}>Past Notifications</h1>
          <div className={styles.filters}>
            <input type="text" placeholder="Search notifications by title..." className={styles.search} />
            <select className={styles.select}>
              <option>Audience: All</option>
              <option>All Users</option>
              <option>Category</option>
              <option>Language</option>
            </select>
            <select className={styles.select}>
              <option>Status: Sent</option>
              <option>Sent</option>
              <option>Scheduled</option>
              <option>Draft</option>
            </select>
            <select className={styles.select}>
              <option>Date Range</option>
              <option>Today</option>
              <option>Last 7 days</option>
              <option>Last 30 days</option>
            </select>
          </div>
        </div>

        <div className={styles.content}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Title</th>
                <th>Audience</th>
                <th>Status</th>
                <th>Date & Time</th>
                <th>Sent By</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {notifications.map(notif => (
                <tr key={notif.id}>
                  <td>{notif.title}</td>
                  <td>{notif.audience}</td>
                  <td>
                    <span className={
                      notif.status === 'Sent' ? styles.statusSent :
                      notif.status === 'Scheduled' ? styles.statusScheduled :
                      styles.statusDraft
                    }>
                      {notif.status}
                    </span>
                  </td>
                  <td>{notif.dateTime}</td>
                  <td>{notif.sentBy}</td>
                  <td>
                    <button className={styles.iconBtn}>👁</button>
                    <button className={styles.iconBtn}>🔄</button>
                    <button className={styles.iconBtn}>🗑️</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
