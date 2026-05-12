import { NextRequest, NextResponse } from 'next/server'
import dbConnect from '@/lib/mongodb'
import AdminUser from '@/models/AdminUser'
import bcrypt from 'bcryptjs'

export async function GET() {
  try {
    await dbConnect()
    const adminUsers = await AdminUser.find({}).select('-password')
    return NextResponse.json(adminUsers)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch admin users' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    await dbConnect()
    const data = await request.json()
    
    // Hash password
    const hashedPassword = await bcrypt.hash(data.password, 12)
    
    const adminUser = new AdminUser({
      ...data,
      password: hashedPassword,
      status: 'Active'
    })
    
    await adminUser.save()
    
    const { password, ...userWithoutPassword } = adminUser.toObject()
    return NextResponse.json(userWithoutPassword, { status: 201 })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to create admin user' }, { status: 500 })
  }
}