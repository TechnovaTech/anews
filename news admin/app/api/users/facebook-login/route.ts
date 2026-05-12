import { NextRequest, NextResponse } from 'next/server'
import dbConnect from '@/lib/mongodb'
import User from '@/models/User'

export async function POST(request: NextRequest) {
  try {
    await dbConnect()
    const { email, name, facebookId, state } = await request.json()

    let user = await User.findOne({ 
      $or: [{ email }, { facebookId }]
    })

    if (user) {
      if (!user.facebookId) {
        user.facebookId = facebookId
        await user.save()
      }
      return NextResponse.json({ user }, { status: 200 })
    }

    user = new User({
      name,
      email,
      facebookId,
      state: state || '',
      role: 'user',
      password: 'facebook_auth',
      walletBalance: 0,
      preferences: {
        language: 'EN',
        categories: []
      }
    })

    await user.save()
    return NextResponse.json({ user }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ error: 'Facebook login failed' }, { status: 500 })
  }
}