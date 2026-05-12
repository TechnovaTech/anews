'use client'

import { useState, useEffect } from 'react'
import Sidebar from '@/components/Sidebar'
import LineChart from '@/components/LineChart'
import BarChart from '@/components/BarChart'

export default function DashboardPage() {
  const [stats, setStats] = useState({ users: 0, news: 0, reels: 0, bookmarks: 0 })
  const [latestNews, setLatestNews] = useState<any[]>([])
  const [latestReels, setLatestReels] = useState<any[]>([])
  const [newsEngagement, setNewsEngagement] = useState<number[]>([])
  const [reelsEngagement, setReelsEngagement] = useState<number[]>([])
  const [loading, setLoading] = useState(true)
  useEffect(() => {
    fetchDashboardData()
  }, [])

  const fetchDashboardData = async () => {
    try {
      const [usersRes, newsRes, reelsRes] = await Promise.all([
        fetch('/api/users'),
        fetch('/api/news'),
        fetch('/api/reels')
      ])

      const usersData = await usersRes.json()
      const newsData = await newsRes.json()
      const reelsData = await reelsRes.json()

      setStats({
        users: usersData.users?.length || 0,
        news: newsData.news?.length || 0,
        reels: reelsData.reels?.length || 0,
        bookmarks: 0
      })

      setLatestNews((newsData.news || []).slice(0, 5))
      setLatestReels((reelsData.reels || []).slice(0, 5))

      const newsViews = (newsData.news || []).slice(0, 13).map((n: any) => n.views || 0)
      const reelsViews = (reelsData.reels || []).slice(0, 13).map((r: any) => r.views || 0)
      setNewsEngagement(newsViews)
      setReelsEngagement(reelsViews)
    } catch (err) {
      console.error('Failed to fetch dashboard data:', err)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={styles.container}>
      <Sidebar />
      <div style={styles.main}>
        <header style={styles.header}>
          <input type="text" placeholder="Search..." style={styles.search} />
          <div style={styles.userInfo}>
            <span style={styles.adminName}>Admin Name</span>
            <span style={styles.profile}>Profile</span>
          </div>
        </header>

        <div style={styles.content}>
          <h1 style={styles.title}>Welcome Admin, here's today's overview</h1>

          <div style={styles.statsGrid}>
            <div style={styles.statCard}>
              <div style={styles.statLabel}>Total Users</div>
              <div style={styles.statValue}>{loading ? '...' : stats.users}</div>
            </div>
            <div style={styles.statCard}>
              <div style={styles.statLabel}>Total Articles</div>
              <div style={styles.statValue}>{loading ? '...' : stats.news}</div>
            </div>
            <div style={styles.statCard}>
              <div style={styles.statLabel}>Total Reels</div>
              <div style={styles.statValue}>{loading ? '...' : stats.reels}</div>
            </div>
            <div style={styles.statCard}>
              <div style={styles.statLabel}>Total Bookmarks/Shares</div>
              <div style={styles.statValue}>{loading ? '...' : stats.bookmarks}</div>
            </div>
          </div>

          <div style={styles.chartsGrid}>
            <div style={styles.chartCard}>
              <h3 style={styles.chartTitle}>Active Users</h3>
              <LineChart data={stats.users} />
            </div>
            <div style={styles.chartCard}>
              <h3 style={styles.chartTitle}>Content Views</h3>
              <BarChart newsData={newsEngagement} reelsData={reelsEngagement} />
            </div>
          </div>

          <div style={styles.listsGrid}>
            <div style={styles.listCard}>
              <h3 style={styles.listTitle}>Latest News Entries</h3>
              {loading ? (
                <div style={{ textAlign: 'center', padding: '20px' }}>Loading...</div>
              ) : latestNews.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '20px' }}>No news found</div>
              ) : (
                latestNews.map((news) => (
                  <div key={news._id} style={styles.listItem}>
                    <span>{news.title}</span>
                    <a href={`/news/edit/${news._id}`} style={styles.editLink}>Edit</a>
                  </div>
                ))
              )}
            </div>
            <div style={styles.listCard}>
              <h3 style={styles.listTitle}>Latest Reels</h3>
              {loading ? (
                <div style={{ textAlign: 'center', padding: '20px' }}>Loading...</div>
              ) : latestReels.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '20px' }}>No reels found</div>
              ) : (
                latestReels.map((reel) => (
                  <div key={reel._id} style={styles.listItem}>
                    <span>{reel.title}</span>
                    <a href={`/reels/edit/${reel._id}`} style={styles.editLink}>Edit</a>
                  </div>
                ))
              )}
            </div>
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
  },
  main: {
    marginLeft: '250px',
    flex: 1,
    backgroundColor: '#f5f5f5',
    minHeight: '100vh',
  },
  header: {
    backgroundColor: 'white',
    padding: '18px 35px',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderBottom: '1px solid #e0e0e0',
  },
  search: {
    padding: '10px 16px',
    border: '1px solid #ddd',
    borderRadius: '5px',
    width: '280px',
    fontSize: '14px',
  },
  userInfo: {
    display: 'flex',
    gap: '25px',
    alignItems: 'center',
  },
  adminName: {
    fontSize: '15px',
    fontWeight: '600' as const,
  },
  profile: {
    fontSize: '15px',
    fontWeight: '600' as const,
  },
  content: {
    padding: '35px',
  },
  title: {
    color: '#e31e3a',
    fontSize: '26px',
    marginBottom: '35px',
    fontWeight: '600' as const,
  },
  statsGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(4, 1fr)',
    gap: '25px',
    marginBottom: '35px',
  },
  statCard: {
    backgroundColor: 'white',
    padding: '28px',
    borderRadius: '8px',
    boxShadow: '0 2px 6px rgba(0,0,0,0.08)',
  },
  statLabel: {
    fontSize: '15px',
    color: '#333',
    marginBottom: '12px',
    fontWeight: '700' as const,
  },
  statValue: {
    fontSize: '34px',
    fontWeight: '700' as const,
    color: '#333',
  },
  chartsGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: '25px',
    marginBottom: '35px',
  },
  chartCard: {
    backgroundColor: 'white',
    padding: '28px',
    borderRadius: '8px',
    boxShadow: '0 2px 6px rgba(0,0,0,0.08)',
  },
  chartTitle: {
    fontSize: '17px',
    fontWeight: '600' as const,
    marginBottom: '25px',
  },
  listsGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: '25px',
  },
  listCard: {
    backgroundColor: 'white',
    padding: '28px',
    borderRadius: '8px',
    boxShadow: '0 2px 6px rgba(0,0,0,0.08)',
  },
  listTitle: {
    fontSize: '17px',
    fontWeight: '600' as const,
    marginBottom: '25px',
  },
  listItem: {
    display: 'flex',
    justifyContent: 'space-between',
    padding: '16px 0',
    borderBottom: '1px solid #f0f0f0',
    fontSize: '15px',
  },
  editLink: {
    color: '#e31e3a',
    textDecoration: 'none',
    fontSize: '14px',
    fontWeight: '500' as const,
  },
}
