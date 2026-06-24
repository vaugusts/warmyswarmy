import React from 'react'
import Button from './components/Button'

export default function App(){
  return (
    <div className="min-h-screen bg-bg text-gray-900 p-6">
      <header className="mb-6">
        <h1 className="text-2xl font-bold">UI Design System</h1>
      </header>
      <main>
        <Button onClick={()=>alert('clicked')}>Primary</Button>
      </main>
    </div>
  )
}
