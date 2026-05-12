'use client'

import { useState, useEffect } from 'react'
import Sidebar from '@/components/Sidebar'

export default function ReportsPage() {
  const [stats, setStats] = useState({ total: 0, active: 0, articles: 0, reels: 0 })
  const [topArticles, setTopArticles] = useState<any[]>([])
  const [topReels, setTopReels] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchReportsData()
  }, [])

  const fetchReportsData = async () => {
    try {
      const [usersRes, newsRes, reelsRes] = await Promise.all([
        fetch('/api/users'),
        fetch('/api/news?status=all'),
        fetch('/api/reels?status=all')
      ])

      const usersData = await usersRes.json()
      const newsData = await newsRes.json()
      const reelsData = await reelsRes.json()

      const users = usersData.users || []
      const news = newsData.news || []
      const reels = reelsData.reels || []

      setStats({
        total: users.length,
        active: users.filter((u: any) => u.isActive).length,
        articles: news.length,
        reels: reels.length
      })

      setTopArticles(news.sort((a: any, b: any) => (b.views || 0) - (a.views || 0)).slice(0, 10))
      setTopReels(reels.sort((a: any, b: any) => (b.views || 0) - (a.views || 0)).slice(0, 10))
    } catch (err) {
      console.error('Failed to fetch reports data:', err)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={styles.container}>
      <Sidebar />
      <div style={styles.main}>
        <header style={styles.header}>
          <h1 style={styles.title}>Analytics & Reports</h1>
          <select style={styles.dateFilter}>
            <option>Today</option>
          </select>
        </header>

        <div style={styles.statsGrid}>
          <div style={styles.statCard}>
            <div style={styles.iconRed}>👥</div>
            <div style={styles.statLabel}>Total</div>
            <div style={styles.statValue}>{loading ? '...' : stats.total}</div>
          </div>
          <div style={styles.statCard}>
            <div style={styles.iconRed}>👤</div>
            <div style={styles.statLabel}>Active Users</div>
            <div style={styles.statValue}>{loading ? '...' : stats.active}</div>
          </div>
          <div style={styles.statCard}>
            <div style={styles.iconRed}>📄</div>
            <div style={styles.statLabel}>Total Articles</div>
            <div style={styles.statValue}>{loading ? '...' : stats.articles}</div>
          </div>
          <div style={styles.statCard}>
            <div style={styles.iconRed}>🎬</div>
            <div style={styles.statLabel}>Total Reels</div>
            <div style={styles.statValue}>{loading ? '...' : stats.reels}</div>
          </div>
        </div>

        <div style={styles.chartsGrid}>
          <div style={styles.chartCard}>
            <h3 style={styles.chartTitle}>User Growth</h3>
            <svg width="100%" height="200" style={{marginTop: '20px'}}>
              <polyline points="20,150 60,120 100,140 140,100 180,110 220,80 260,90 300,60 340,50" stroke="#9ca3af" strokeWidth="2" fill="none"/>
              <polyline points="20,100 60,110 100,90 140,100 180,120 220,110 260,130 300,140 340,150" stroke="#e31e3a" strokeWidth="2" fill="none"/>
            </svg>
          </div>
          <div style={styles.chartCard}>
            <h3 style={styles.chartTitle}>Engagement by Content Type</h3>
            <div style={{marginTop: '30px'}}>
              {[{gray: 60, red: 40}, {gray: 85, red: 15}, {gray: 70, red: 30}, {gray: 60, red: 40}].map((bar, i) => (
                <div key={i} style={{display: 'flex', marginBottom: '15px', height: '25px'}}>
                  <div style={{width: `${bar.gray}%`, backgroundColor: '#9ca3af'}}></div>
                  <div style={{width: `${bar.red}%`, backgroundColor: '#e31e3a'}}></div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div style={styles.chartsGrid}>
          <div style={styles.chartCard}>
            <h3 style={styles.chartTitle}>Category Performance</h3>
            <div style={{display: 'flex', justifyContent: 'center', alignItems: 'center', height: '200px'}}>
              <svg width="200" height="200">
                <circle cx="100" cy="100" r="80" fill="#e31e3a" stroke="none"/>
                <path d="M 100 100 L 100 20 A 80 80 0 0 1 180 100 Z" fill="#9ca3af"/>
              </svg>
            </div>
          </div>
          <div style={styles.chartCard}>
            <h3 style={styles.chartTitle}>Language Distribution</h3>
            <div style={{display: 'flex', alignItems: 'flex-end', justifyContent: 'space-around', height: '200px', marginTop: '20px'}}>
              {[60, 40, 80, 70, 55, 30, 75, 70].map((h, i) => (
                <div key={i} style={{display: 'flex', flexDirection: 'column', alignItems: 'center', width: '30px'}}>
                  <div style={{width: '30px', height: `${h}%`, backgroundColor: '#e31e3a', marginBottom: '2px'}}></div>
                  <div style={{width: '30px', height: `${100-h}%`, backgroundColor: '#9ca3af'}}></div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div style={styles.tableCard}>
          <h3 style={styles.tableTitle}>Top 10 Articles</h3>
          <table style={styles.table}>
            <thead>
              <tr>
                <th style={styles.th}>Title</th>
                <th style={styles.th}>Views</th>
                <th style={styles.th}>Likes</th>
                <th style={styles.th}>Shares</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={4} style={{...styles.td, textAlign: 'center'}}>Loading...</td></tr>
              ) : topArticles.length === 0 ? (
                <tr><td colSpan={4} style={{...styles.td, textAlign: 'center'}}>No articles found</td></tr>
              ) : (
                topArticles.map((article) => (
                  <tr key={article._id} style={styles.tr}>
                    <td style={styles.td}>{article.title}</td>
                    <td style={styles.td}>{article.views || 0}</td>
                    <td style={styles.td}>{article.likes || 0}</td>
                    <td style={styles.td}>{article.shares || 0}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div style={styles.tableCard}>
          <h3 style={styles.tableTitle}>Top 10 Reels</h3>
          <table style={styles.table}>
            <thead>
              <tr>
                <th style={styles.th}>Title</th>
                <th style={styles.th}>Views</th>
                <th style={styles.th}>Likes</th>
                <th style={styles.th}>Comments</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={4} style={{...styles.td, textAlign: 'center'}}>Loading...</td></tr>
              ) : topReels.length === 0 ? (
                <tr><td colSpan={4} style={{...styles.td, textAlign: 'center'}}>No reels found</td></tr>
              ) : (
                topReels.map((reel) => (
                  <tr key={reel._id} style={styles.tr}>
                    <td style={styles.td}>{reel.title}</td>
                    <td style={styles.td}>{reel.views || 0}</td>
                    <td style={styles.td}>{reel.likes || 0}</td>
                    <td style={styles.td}>{reel.comments || 0}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div style={styles.exportButtons}>
          <button style={styles.exportBtnRed}>Export as PDF</button>
          <button style={styles.exportBtnWhite}>Export as CSV</button>
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
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '30px',
  },
  title: {
    fontSize: '24px',
    fontWeight: '700' as const,
    color: '#000',
  },
  dateFilter: {
    padding: '8px 16px',
    border: '1px solid #ddd',
    borderRadius: '5px',
    fontSize: '14px',
    backgroundColor: 'white',
  },
  statsGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(4, 1fr)',
    gap: '20px',
    marginBottom: '30px',
  },
  statCard: {
    backgroundColor: 'white',
    padding: '20px',
    borderRadius: '8px',
    boxShadow: '0 2px 4px rgba(0,0,0,0.06)',
  },
  iconRed: {
    fontSize: '24px',
    marginBottom: '8px',
  },
  statLabel: {
    fontSize: '14px',
    color: '#000',
    fontWeight: '700' as const,
    marginBottom: '5px',
  },
  statValue: {
    fontSize: '24px',
    fontWeight: '700' as const,
    color: '#000',
  },
  chartsGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: '20px',
    marginBottom: '30px',
  },
  chartCard: {
    backgroundColor: 'white',
    padding: '25px',
    borderRadius: '8px',
    boxShadow: '0 2px 4px rgba(0,0,0,0.06)',
  },
  chartTitle: {
    fontSize: '16px',
    fontWeight: '700' as const,
    color: '#000',
    marginBottom: '10px',
  },
  tableCard: {
    backgroundColor: 'white',
    padding: '25px',
    borderRadius: '8px',
    boxShadow: '0 2px 4px rgba(0,0,0,0.06)',
    marginBottom: '30px',
  },
  tableTitle: {
    fontSize: '16px',
    fontWeight: '700' as const,
    color: '#000',
    marginBottom: '20px',
  },
  table: {
    width: '100%',
    borderCollapse: 'collapse' as const,
  },
  th: {
    textAlign: 'left' as const,
    padding: '12px',
    borderBottom: '2px solid #f0f0f0',
    fontSize: '14px',
    fontWeight: '700' as const,
    color: '#000',
  },
  tr: {
    borderBottom: '1px solid #f0f0f0',
  },
  td: {
    padding: '12px',
    fontSize: '14px',
    color: '#333',
  },
  exportButtons: {
    display: 'flex',
    justifyContent: 'flex-end',
    gap: '15px',
    marginTop: '20px',
  },
  exportBtnRed: {
    backgroundColor: '#e31e3a',
    color: 'white',
    padding: '12px 24px',
    border: 'none',
    borderRadius: '25px',
    fontSize: '14px',
    fontWeight: '600' as const,
    cursor: 'pointer',
  },
  exportBtnWhite: {
    backgroundColor: 'white',
    color: '#000',
    padding: '12px 24px',
    border: '1px solid #ddd',
    borderRadius: '25px',
    fontSize: '14px',
    fontWeight: '600' as const,
    cursor: 'pointer',
  },
}
