"use client"

import Sidebar from '@/components/Sidebar'
import Link from 'next/link'
import React, { useState, useEffect } from 'react'
import styles from '../page.module.css'

export default function ViewNewsPage({ params }: { params: Promise<{ id: string }> }) {
  const [newsData, setNewsData] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [id, setId] = useState<string>('')

  useEffect(() => {
    params.then(p => {
      setId(p.id)
      fetchNews(p.id)
    })
  }, [])

  const fetchNews = async (newsId: string) => {
    try {
      const res = await fetch(`/api/news/${newsId}`)
      const data = await res.json()
      setNewsData(data.news)
    } catch (error) {
      console.error('Failed to fetch news:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) return <div>Loading...</div>
  if (!newsData) return <div>News not found</div>

  return (
    <div className={styles.container}>
      <Sidebar />
      <div className={styles.main}>
        <div className={styles.header}>
          <h1 className={styles.title}>News Details</h1>
          <Link href="/news" className={styles.backBtn}>
            ← Back to All News
          </Link>
        </div>

        <div className={styles.content}>
          <div className={styles.articleContainer}>
            {newsData.image && <img src={newsData.image} alt={newsData.title} className={styles.articleImage} />}
            {newsData.videoUrl && (
              <div style={{ marginTop: '20px' }}>
                <video 
                  src={newsData.videoUrl} 
                  controls 
                  style={{ width: '100%', maxHeight: '500px', borderRadius: '8px' }}
                />
              </div>
            )}
            <h2 className={styles.articleHeadline}>{newsData.title}</h2>
            <p className={styles.articleSummary}>{newsData.summary}</p>
          </div>

          <aside className={styles.rightPanel}>
            <div className={styles.metaTitle}>Headline</div>
            <div className={styles.metaItem}>{newsData.title}</div>

            <div className={styles.metaTitle}>Summary</div>
            <div className={styles.metaItem}>{newsData.summary}</div>

            <div className={styles.metaTitle}>Full Article Link</div>
            <div className={styles.metaItem}>
              <a href={newsData.content} target="_blank" rel="noreferrer">
                Read Full Article
              </a>
            </div>

            <div className={styles.metaTitle}>Category</div>
            <div className={styles.metaItem}>{newsData.category?.name || 'N/A'}</div>

            <div className={styles.metaTitle}>Language</div>
            <div className={styles.metaItem}>{newsData.language || 'EN'}</div>

            <div className={styles.metaTitle}>Tags</div>
            <div className={styles.metaItem}>
              {newsData.tags?.map((tag: any) => tag.name).join(', ') || 'No tags'}
            </div>

            <div className={styles.metaTitle}>Source</div>
            <div className={styles.metaItem}>{newsData.source || 'N/A'}</div>

            <div className={styles.metaTitle}>State</div>
            <div className={styles.metaItem}>{newsData.state || 'All'}</div>

            <div className={styles.metaTitle}>Status</div>
            <div className={styles.metaItem}>{newsData.status}</div>

            <div className={styles.metaTitle}>Date Created</div>
            <div className={styles.metaItem}>{new Date(newsData.createdAt).toLocaleString()}</div>

            <div className={styles.buttonRow}>
              <Link href={`/news/edit/${id}`} className={styles.editBtn}>
                Edit News
              </Link>
              <Link href="/news" className={styles.backBtn}>
                Back to All News
              </Link>
            </div>
          </aside>
        </div>
      </div>
    </div>
  )
}