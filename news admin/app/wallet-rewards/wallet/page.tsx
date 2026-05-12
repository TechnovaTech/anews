'use client';

import Sidebar from '@/components/Sidebar';
import { useState, useEffect } from 'react';
import styles from './wallet.module.css';

export default function WalletManagement() {
  const [wallets, setWallets] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [showAdjustModal, setShowAdjustModal] = useState(false);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [adjustAmount, setAdjustAmount] = useState(0);
  const [stats, setStats] = useState({ savePoints: 0, sharePoints: 0, referralPoints: 0, totalReferrals: 0 });
  const [pointSettings, setPointSettings] = useState({
    savePoints: 5,
    sharePoints: 10,
    referralGiverPoints: 50,
    referralReceiverPoints: 30
  });

  useEffect(() => {
    fetchPointSettings();
    fetchWalletData();
  }, []);

  const fetchPointSettings = async () => {
    try {
      const res = await fetch('/api/point-settings');
      const data = await res.json();
      setPointSettings(data);
    } catch (err) {
      console.error('Failed to fetch settings:', err);
    }
  };

  const fetchWalletData = async () => {
    try {
      const res = await fetch('/api/wallet');
      const data = await res.json();
      setWallets(data.users || []);
      setStats({
        savePoints: data.stats.totalSavePoints || 0,
        sharePoints: data.stats.totalSharePoints || 0,
        referralPoints: data.stats.totalReferralPoints || 0,
        totalReferrals: data.stats.totalReferrals || 0
      });
    } catch (err) {
      console.error('Failed to fetch wallet data:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleAdjustPoints = async (action: 'increase' | 'decrease') => {
    if (!selectedUser || adjustAmount <= 0) return;
    try {
      console.log('Adjusting points:', { userId: selectedUser.id, action, amount: adjustAmount });
      const res = await fetch(`/api/wallet/${selectedUser.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action, amount: adjustAmount })
      });
      const data = await res.json();
      console.log('Response:', data);
      if (res.ok) {
        alert(`Points adjusted successfully! New balance: ${data.balance}`);
        setShowAdjustModal(false);
        setAdjustAmount(0);
        fetchWalletData();
      } else {
        alert(`Failed: ${data.error || 'Unknown error'}`);
      }
    } catch (err) {
      console.error('Failed to adjust points:', err);
      alert('Failed to adjust points');
    }
  };

  const handleSaveSettings = async () => {
    try {
      const res = await fetch('/api/point-settings', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(pointSettings)
      });
      if (res.ok) {
        alert('Settings saved successfully');
        setShowModal(false);
      }
    } catch (err) {
      console.error('Failed to save settings:', err);
      alert('Failed to save settings');
    }
  };

  return (
    <div className={styles.container}>
      <Sidebar />
      <div className={styles.main}>
      <div className={styles.header}>
        <div>
          <h1>Wallet Management</h1>
          <p>Manage user wallet balances and transactions</p>
        </div>
        <button className={styles.settingsBtn} onClick={() => setShowModal(true)}>⚙️ Adjust Point Values</button>
      </div>

      <div className={styles.statsGrid}>
        <div className={styles.statCard}>
          <div className={styles.statIcon}>💾</div>
          <div className={styles.statValue}>{stats.savePoints}</div>
          <div className={styles.statLabel}>Save Points</div>
        </div>
        <div className={styles.statCard}>
          <div className={styles.statIcon}>📤</div>
          <div className={styles.statValue}>{stats.sharePoints}</div>
          <div className={styles.statLabel}>Share Points</div>
        </div>
        <div className={styles.statCard}>
          <div className={styles.statIcon}>🎁</div>
          <div className={styles.statValue}>{stats.referralPoints}</div>
          <div className={styles.statLabel}>Referral Points</div>
        </div>
        <div className={styles.statCard}>
          <div className={styles.statIcon}>👥</div>
          <div className={styles.statValue}>{stats.totalReferrals}</div>
          <div className={styles.statLabel}>Total Referrals</div>
        </div>
      </div>

      {loading ? (
        <div className={styles.loading}>Loading...</div>
      ) : (
        <div className={styles.tableContainer}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>User Name</th>
                <th>Email</th>
                <th>Balance (Points)</th>
                <th>Transactions</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {wallets.map((wallet) => (
                <tr key={wallet.id}>
                  <td>{wallet.userName}</td>
                  <td>{wallet.email}</td>
                  <td className={styles.balance}>{wallet.balance}</td>
                  <td>{wallet.transactions}</td>
                  <td>
                    <button className={styles.btnView}>View Details</button>
                    <button className={styles.btnAdjust} onClick={() => { setSelectedUser(wallet); setShowAdjustModal(true); }}>Adjust Points</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {showModal && (
        <div className={styles.modal}>
          <div className={styles.modalContent}>
            <h2>Adjust Point Values</h2>
            <div className={styles.formGroup}>
              <label>Save Points (Article & Reel)</label>
              <input type="number" value={pointSettings.savePoints} onChange={(e) => setPointSettings({...pointSettings, savePoints: Number(e.target.value)})} />
            </div>
            <div className={styles.formGroup}>
              <label>Share Points (Article & Reel)</label>
              <input type="number" value={pointSettings.sharePoints} onChange={(e) => setPointSettings({...pointSettings, sharePoints: Number(e.target.value)})} />
            </div>
            <div className={styles.formGroup}>
              <label>Referral Giver Points (User who refers)</label>
              <input type="number" value={pointSettings.referralGiverPoints} onChange={(e) => setPointSettings({...pointSettings, referralGiverPoints: Number(e.target.value)})} />
            </div>
            <div className={styles.formGroup}>
              <label>Referral Receiver Points (Referred user)</label>
              <input type="number" value={pointSettings.referralReceiverPoints} onChange={(e) => setPointSettings({...pointSettings, referralReceiverPoints: Number(e.target.value)})} />
            </div>
            <div className={styles.modalButtons}>
              <button className={styles.btnCancel} onClick={() => setShowModal(false)}>Cancel</button>
              <button className={styles.btnSave} onClick={handleSaveSettings}>Save</button>
            </div>
          </div>
        </div>
      )}

      {showAdjustModal && selectedUser && (
        <div className={styles.modal}>
          <div className={styles.modalContent}>
            <h2>Adjust Points - {selectedUser.userName}</h2>
            <p>Current Balance: {selectedUser.balance} points</p>
            <div className={styles.formGroup}>
              <label>Amount</label>
              <input type="number" value={adjustAmount} onChange={(e) => setAdjustAmount(Number(e.target.value))} placeholder="Enter amount" />
            </div>
            <div className={styles.modalButtons}>
              <button className={styles.btnCancel} onClick={() => { setShowAdjustModal(false); setAdjustAmount(0); }}>Cancel</button>
              <button className={styles.btnIncrease} onClick={() => handleAdjustPoints('increase')}>Increase</button>
              <button className={styles.btnDecrease} onClick={() => handleAdjustPoints('decrease')}>Decrease</button>
            </div>
          </div>
        </div>
      )}
      </div>
    </div>
  );
}
