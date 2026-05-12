import { NextResponse } from 'next/server';

export function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
}

export function createCorsResponse(data: any, options: { status?: number } = {}) {
  return NextResponse.json(data, {
    status: options.status || 200,
    headers: corsHeaders(),
  });
}

export function createCorsErrorResponse(error: string, status: number = 500) {
  return NextResponse.json({ error }, {
    status,
    headers: corsHeaders(),
  });
}

export function handleOptionsRequest() {
  return new NextResponse(null, {
    status: 200,
    headers: corsHeaders(),
  });
}