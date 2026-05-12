'use client';

import Sidebar from '@/components/Sidebar';
import { useState, useEffect } from 'react';
import styles from './rewards.module.css';

export default function RewardManagement() {
  const [rewards, setRewards] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingReward, setEditingReward] = useState<any>(null);
  const [formData, setFormData] = useState({ name: '', points: 0, available: true, imageUrl: '', description: '', terms: '', redeemCode: '' });
  const [uploading, setUploading] = useState(false);

  useEffect(() => {
    fetchRewards();
  }, []);

  const fetchRewards = async () => {
    try {
      const res = await fetch('/api/rewards');
      const data = await res.json();
      setRewards(data.rewards || []);
    } catch (err) {
      console.error('Failed to fetch rewards:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async () => {
    try {
      if (editingReward) {
        const res = await fetch(`/api/rewards/${editingReward._id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(formData)
        });
        if (res.ok) alert('Reward updated successfully');
      } else {
        const res = await fetch('/api/rewards', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(formData)
        });
        if (res.ok) alert('Reward added successfully');
      }
      setShowModal(false);
      setEditingReward(null);
      setFormData({ name: '', points: 0, available: true, imageUrl: '', description: '', terms: '', redeemCode: '' });
      fetchRewards();
    } catch (err) {
      console.error('Failed to save reward:', err);
      alert('Failed to save reward');
    }
  };

  const handleEdit = (reward: any) => {
    setEditingReward(reward);
    setFormData({ name: reward.name, points: reward.points, available: reward.available, imageUrl: reward.imageUrl || '', description: reward.description || '', terms: reward.terms || '', redeemCode: reward.redeemCode || '' });
    setShowModal(true);
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    const data = new FormData();
    data.append('file', file);
    try {
      const res = await fetch('/api/upload', { method: 'POST', body: data });
      const result = await res.json();
      setFormData({...formData, imageUrl: result.url});
    } catch (error) {
      alert('Failed to upload image');
    } finally {
      setUploading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this reward?')) return;
    try {
      const res = await fetch(`/api/rewards/${id}`, { method: 'DELETE' });
      if (res.ok) {
        alert('Reward deleted successfully');
        fetchRewards();
      }
    } catch (err) {
      console.error('Failed to delete reward:', err);
      alert('Failed to delete reward');
    }
  };

  return (
    <div className={styles.container}>
      <Sidebar />
      <div className={styles.main}>
      <div className={styles.header}>
        <h1>Reward Management</h1>
        <p>Manage available rewards and redemptions</p>
        <button className={styles.btnAdd} onClick={() => { setShowModal(true); setEditingReward(null); setFormData({ name: '', points: 0, available: true, imageUrl: '', description: '', terms: '', redeemCode: '' }); }}>+ Add New Reward</button>
      </div>

      {loading ? (
        <div className={styles.loading}>Loading...</div>
      ) : (
        <div className={styles.grid}>
          {rewards.map((reward) => (
            <div key={reward._id} className={styles.card}>
              {reward.imageUrl && <img src={reward.imageUrl} alt={reward.name} className={styles.cardImage} />}
              <div className={styles.cardHeader}>
                <h3>{reward.name}</h3>
                <span className={reward.available ? styles.badgeActive : styles.badgeInactive}>
                  {reward.available ? 'Active' : 'Inactive'}
                </span>
              </div>
              <div className={styles.cardBody}>
                {reward.description && <p className={styles.description}>{reward.description}</p>}
                <div className={styles.info}>
                  <span className={styles.label}>Points Required:</span>
                  <span className={styles.value}>{reward.points} pts</span>
                </div>
                {reward.redeemCode && (
                  <div className={styles.info}>
                    <span className={styles.label}>Redeem Code:</span>
                    <span className={styles.value}>{reward.redeemCode}</span>
                  </div>
                )}
                <div className={styles.info}>
                  <span className={styles.label}>Times Redeemed:</span>
                  <span className={styles.value}>{reward.redeemed}</span>
                </div>
                {reward.terms && (
                  <div className={styles.termsSection}>
                    <span className={styles.label}>Terms & Conditions:</span>
                    <p className={styles.termsText}>{reward.terms}</p>
                  </div>
                )}
              </div>
              <div className={styles.cardFooter}>
                <button className={styles.btnEdit} onClick={() => handleEdit(reward)}>Edit</button>
                <button className={styles.btnDelete} onClick={() => handleDelete(reward._id)}>Delete</button>
              </div>
            </div>
          ))}
        </div>
      )}

      {showModal && (
        <div className={styles.modal}>
          <div className={styles.modalContent}>
            <h2>{editingReward ? 'Edit Reward' : 'Add New Reward'}</h2>
            <div className={styles.formGroup}>
              <label>Reward Name</label>
              <input type="text" value={formData.name} onChange={(e) => setFormData({...formData, name: e.target.value})} placeholder="e.g. ₹100 Amazon Gift Card" />
            </div>
            <div className={styles.formGroup}>
              <label>Description</label>
              <textarea value={formData.description} onChange={(e) => setFormData({...formData, description: e.target.value})} placeholder="Reward description" rows={3} />
            </div>
            <div className={styles.formGroup}>
              <label>Upload Image</label>
              <input type="file" accept="image/*" onChange={handleImageUpload} disabled={uploading} />
              {uploading && <p>Uploading...</p>}
              {formData.imageUrl && <img src={formData.imageUrl} alt="Preview" style={{ marginTop: '10px', maxWidth: '150px', borderRadius: '8px' }} />}
            </div>
            <div className={styles.formGroup}>
              <label>Points Required</label>
              <input type="number" value={formData.points} onChange={(e) => setFormData({...formData, points: Number(e.target.value)})} placeholder="500" />
            </div>
            <div className={styles.formGroup}>
              <label>Terms and Conditions</label>
              <textarea value={formData.terms} onChange={(e) => setFormData({...formData, terms: e.target.value})} placeholder="Terms and conditions" rows={4} />
            </div>
            <div className={styles.formGroup}>
              <label>Redeem Code</label>
              <input type="text" value={formData.redeemCode} onChange={(e) => setFormData({...formData, redeemCode: e.target.value})} placeholder="e.g. GIFT100" />
            </div>
            <div className={styles.formGroup}>
              <label>
                <input type="checkbox" checked={formData.available} onChange={(e) => setFormData({...formData, available: e.target.checked})} />
                {' '}Available
              </label>
            </div>
            <div className={styles.modalButtons}>
              <button className={styles.btnCancel} onClick={() => { setShowModal(false); setEditingReward(null); }}>Cancel</button>
              <button className={styles.btnSave} onClick={handleSubmit}>Save</button>
            </div>
          </div>
        </div>
      )}
      </div>
    </div>
  );
}
