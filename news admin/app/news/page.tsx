'use client'

import Sidebar from '@/components/Sidebar'
import Link from 'next/link'
import { useState, useEffect } from 'react'

export default function ManageNewsPage() {
  const [newsData, setNewsData] = useState<any[]>([])
  const [allNews, setAllNews] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedLang, setSelectedLang] = useState<string>('ALL')

  useEffect(() => {
    fetchNews()
  }, [])

  const fetchNews = async () => {
    try {
      const res = await fetch('/api/news?status=all')
      const data = await res.json()
      setAllNews(data.news || [])
      setNewsData(data.news || [])
    } catch (error) {
      console.error('Failed to fetch news:', error)
    } finally {
      setLoading(false)
    }
  }

  const filterByLanguage = (lang: string) => {
    setSelectedLang(lang)
    if (lang === 'ALL') {
      setNewsData(allNews)
    } else {
      setNewsData(allNews.filter(news => news.languages?.includes(lang)))
    }
  }

  const handleDelete = async (id: string) => {
    if (confirm('Delete this news?')) {
      try {
        await fetch(`/api/news/${id}`, { method: 'DELETE' })
        fetchNews()
      } catch (error) {
        console.error('Failed to delete news:', error)
      }
    }
  }

  return (
    <div style={styles.container}>
      <Sidebar />
      <div style={styles.main}>
        <div style={styles.header}>
          <h1 style={styles.title}>Manage News – All News</h1>
          <div style={{ display: 'flex', gap: '10px', marginRight: 'auto', marginLeft: '20px' }}>
            {['ALL', 'EN', 'HIN', 'BEN'].map(lang => (
              <button
                key={lang}
                onClick={() => filterByLanguage(lang)}
                style={{
                  padding: '8px 16px',
                  border: 'none',
                  backgroundColor: selectedLang === lang ? '#e31e3a' : '#f0f0f0',
                  color: selectedLang === lang ? 'white' : '#333',
                  borderRadius: '5px',
                  cursor: 'pointer',
                  fontWeight: '600',
                  fontSize: '13px'
                }}
              >
                {lang}
              </button>
            ))}
          </div>
          <Link href="/news/add" style={styles.addBtn}>+ Add News</Link>
          <input type="text" placeholder="Search by headline or tags" style={styles.search} />
          <select style={styles.select}>
            <option>Category</option>
          </select>
          <select style={styles.select}>
            <option>Language</option>
          </select>
          <select style={styles.select}>
            <option>Status</option>
          </select>
        </div>

        <div style={styles.content}>
          <table style={styles.table}>
            <thead>
              <tr style={styles.tableHeader}>
                <th style={styles.th}></th>
                <th style={styles.th}>Headline</th>
                <th style={styles.th}>Category</th>
                <th style={styles.th}>State</th>
                <th style={styles.th}>Language</th>
                <th style={styles.th}>Status</th>
                <th style={styles.th}>Date Created</th>
                <th style={styles.th}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={8} style={{ ...styles.td, textAlign: 'center' }}>Loading...</td>
                </tr>
              ) : newsData.length === 0 ? (
                <tr>
                  <td colSpan={8} style={{ ...styles.td, textAlign: 'center' }}>No news found</td>
                </tr>
              ) : (
                newsData.map((news) => {
                  const displayLang = selectedLang === 'ALL' ? 'EN' : selectedLang
                  const title = news.translations?.[displayLang]?.title || news.title
                  const availableLanguages = news.languages && news.languages.length > 0 ? news.languages : ['EN']
                  
                  return (
                    <tr key={news._id} style={styles.tableRow}>
                      <td style={styles.td}>
                        <input type="checkbox" />
                      </td>
                      <td style={styles.td}>{title}</td>
                      <td style={styles.td}>
                        <span style={{
                          ...styles.badge,
                          backgroundColor: '#e31e3a'
                        }}>
                          {news.category?.name || 'Uncategorized'}
                        </span>
                      </td>
                      <td style={styles.td}>{news.state || 'All'}</td>
                      <td style={styles.td}>{availableLanguages.join(', ')}</td>
                      <td style={styles.td}>
                        <span style={{
                          ...styles.badge,
                          backgroundColor: news.status === 'published' ? '#28a745' : '#e31e3a'
                        }}>
                          {news.status}
                        </span>
                      </td>
                      <td style={styles.td}>{new Date(news.createdAt).toLocaleDateString()}</td>
                      <td style={styles.td}>
                        <Link href={`/news/edit/${news._id}`} style={styles.actionLink}>Edit</Link>
                        <Link href={`/news/view/${news._id}`} style={styles.actionLink}>View</Link>
                        <a href="#" onClick={(e) => { e.preventDefault(); handleDelete(news._id); }} style={styles.actionLink}>Delete</a>
                      </td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
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
    padding: '20px 35px',
    display: 'flex',
    alignItems: 'center',
    gap: '15px',
    borderBottom: '1px solid #e0e0e0',
  },
  title: {
    fontSize: '22px',
    fontWeight: '600' as const,
    marginRight: 'auto',
  },
  addBtn: {
    backgroundColor: '#e31e3a',
    color: 'white',
    padding: '10px 25px',
    borderRadius: '25px',
    textDecoration: 'none',
    fontSize: '14px',
    fontWeight: '600' as const,
  },
  search: {
    padding: '10px 16px',
    border: '1px solid #ddd',
    borderRadius: '5px',
    width: '250px',
    fontSize: '14px',
  },
  select: {
    padding: '10px 16px',
    border: '1px solid #ddd',
    borderRadius: '5px',
    fontSize: '14px',
    backgroundColor: 'white',
    cursor: 'pointer',
  },
  content: {
    padding: '35px',
  },
  table: {
    width: '100%',
    backgroundColor: 'white',
    borderRadius: '8px',
    overflow: 'hidden',
    boxShadow: '0 2px 6px rgba(0,0,0,0.08)',
  },
  tableHeader: {
    backgroundColor: '#e8e8e8',
  },
  th: {
    padding: '18px 20px',
    textAlign: 'left' as const,
    fontSize: '14px',
    fontWeight: '600' as const,
    color: '#333',
  },
  tableRow: {
    borderBottom: '1px solid #f0f0f0',
  },
  td: {
    padding: '18px 20px',
    fontSize: '14px',
    color: '#333',
  },
  badge: {
    padding: '6px 16px',
    borderRadius: '20px',
    color: 'white',
    fontSize: '13px',
    fontWeight: '500' as const,
    display: 'inline-block',
  },
  actionLink: {
    color: '#e31e3a',
    textDecoration: 'none',
    fontSize: '14px',
    marginRight: '15px',
    fontWeight: '500' as const,
  },
}
