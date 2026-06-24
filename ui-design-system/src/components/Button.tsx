import React from 'react'

type Props = React.ButtonHTMLAttributes<HTMLButtonElement>

export default function Button({children, className='', ...rest}: Props){
  return (
    <button
      className={`px-4 py-2 rounded-md bg-primary text-white hover:opacity-95 focus:outline-none ${className}`}
      {...rest}
    >
      {children}
    </button>
  )
}
