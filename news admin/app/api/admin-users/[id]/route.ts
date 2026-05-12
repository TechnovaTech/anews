import { NextRequest, NextResponse } from 'next/server'
import dbConnect from '@/lib/mongodb'
import AdminUser from '@/models/AdminUser'
import bcrypt from 'bcryptjs'

export async function PUT(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    await dbConnect()
    const { id } = await params
    const data = await request.json()
    
    const updateData: any = { ...data }
    
    // Hash password if provided
    if (data.password && data.password.trim() !== '') {
      updateData.password = await bcrypt.hash(data.password, 12)
    } else {
      delete updateData.password
    }
    
    const adminUser = await AdminUser.findByIdAndUpdate(
      id,
      updateData,
      { new: true }
    ).select('-password')
    
    if (!adminUser) {
      return NextResponse.json({ error: 'Admin user not found' }, { status: 404 })
    }
    
    return NextResponse.json(adminUser)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to update admin user' }, { status: 500 })
  }
}

export async function DELETE(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    await dbConnect()
    const { id } = await params
    
    const adminUser = await AdminUser.findByIdAndDelete(id)
    
    if (!adminUser) {
      return NextResponse.json({ error: 'Admin user not found' }, { status: 404 })
    }
    
    return NextResponse.json({ message: 'Admin user deleted successfully' })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to delete admin user' }, { status: 500 })
  }
}