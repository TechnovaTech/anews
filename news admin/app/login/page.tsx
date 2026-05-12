'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Image from 'next/image'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    console.log('Login button clicked')
    console.log('Email:', email, 'Password:', password)
    setError('')
    setLoading(true)

    try {
      console.log('Sending request to /api/auth/login')
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
        credentials: 'include'
      })

      console.log('Response status:', res.status)
      const data = await res.json()
      console.log('Response data:', data)

      if (!res.ok) {
        setError(data.error || 'Invalid email or password')
        setLoading(false)
        return
      }

      localStorage.setItem('user', JSON.stringify(data.user))
      console.log('Login successful, redirecting...')
      window.location.href = '/dashboard'
    } catch (err) {
      console.error('Login error:', err)
      setError('Login failed. Please try again.')
      setLoading(false)
    }
  }

  return (
    <div style={styles.container}>
      <div style={styles.loginBox}>
        <Image 
          src="/Red_Logo.png" 
          alt="asiaze" 
          width={200} 
          height={60}
          style={styles.logo}
        />
        
        <form onSubmit={handleLogin} style={styles.form}>
          {error && <div style={styles.error}>{error}</div>}
          
          <div style={styles.inputGroup}>
            <label style={styles.label}>Email</label>
            <input
              type="email"
              placeholder="Enter your email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              style={styles.input}
            />
          </div>

          <div style={styles.inputGroup}>
            <label style={styles.label}>Password</label>
            <input
              type="password"
              placeholder="Enter your password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              style={styles.input}
            />
          </div>

          <a href="#" style={styles.forgotPassword}>Forgot Password?</a>

          <button type="submit" style={styles.loginButton} disabled={loading}>
            {loading ? 'Logging in...' : 'Login'}
          </button>
        </form>
      </div>

      <footer style={styles.footer}>
        <a href="#" style={styles.footerLink}>Terms of Service</a>
        <a href="#" style={styles.footerLink}>Privacy Policy</a>
        <a href="#" style={styles.footerLink}>Contact Us</a>
      </footer>
    </div>
  )
}

const styles = {
  container: {
    minHeight: '100vh',
    display: 'flex',
    flexDirection: 'column' as const,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f5f5f5',
    padding: '20px',
  },
  loginBox: {
    backgroundColor: 'white',
    padding: '60px 40px',
    borderRadius: '8px',
    boxShadow: '0 2px 10px rgba(0,0,0,0.1)',
    width: '100%',
    maxWidth: '400px',
    textAlign: 'center' as const,
  },
  logo: {
    marginBottom: '40px',
  },
  form: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '20px',
  },
  inputGroup: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '8px',
    textAlign: 'left' as const,
  },
  label: {
    fontSize: '14px',
    fontWeight: '600' as const,
    color: '#333',
  },
  input: {
    padding: '12px 16px',
    border: '1px solid #ddd',
    borderRadius: '8px',
    fontSize: '14px',
    outline: 'none',
    transition: 'border-color 0.3s',
  },
  forgotPassword: {
    fontSize: '14px',
    color: '#dc143c',
    textDecoration: 'none',
    fontWeight: '600' as const,
    textAlign: 'right' as const,
    marginTop: '-10px',
  },
  loginButton: {
    backgroundColor: '#dc143c',
    color: 'white',
    padding: '14px',
    border: 'none',
    borderRadius: '25px',
    fontSize: '16px',
    fontWeight: '600' as const,
    cursor: 'pointer',
    marginTop: '10px',
  },
  footer: {
    position: 'absolute' as const,
    bottom: '30px',
    display: 'flex',
    gap: '30px',
  },
  footerLink: {
    fontSize: '14px',
    color: '#333',
    textDecoration: 'none',
  },
  error: {
    backgroundColor: '#fee',
    color: '#c33',
    padding: '12px',
    borderRadius: '8px',
    fontSize: '14px',
    textAlign: 'center' as const,
  },
}
