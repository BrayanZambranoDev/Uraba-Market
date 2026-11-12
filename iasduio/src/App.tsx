import React, { useState } from 'react';
import { Mail, Lock, Eye, ArrowRight, ShieldCheck, Leaf, Truck, Tractor, User, UserPlus, ChevronLeft, ChevronRight, ShoppingBag, Store, Users, Rocket, Check, Camera, Menu, Search, SlidersHorizontal, Bell, Grid, MessageSquare, Sparkles, Plus, MapPin, Home, Heart, Star, HeartPulse } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Checkbox } from '@/components/ui/checkbox';

type Screen = 'login' | 'register' | 'profile-setup' | 'home';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('login');
  const [selectedRole, setSelectedRole] = useState<'comprador' | 'comerciante' | 'productor'>('comprador');

  return (
    <div className="min-h-screen bg-[#051109] text-white font-sans relative overflow-x-hidden flex flex-col items-center">
      <AnimatePresence mode="wait">
        {currentScreen === 'login' && (
          <motion.div
            key="login"
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 20 }}
            transition={{ duration: 0.3 }}
            className="w-full flex flex-col items-center"
          >
            {/* Background Layer: Top Fruit Stand Image */}
            <div 
              className="absolute top-0 inset-x-0 h-[50vh] z-0"
              style={{
                backgroundImage: `url('https://images.unsplash.com/photo-1590779033100-9f60705a2f3b?q=80&w=2787&auto=format&fit=crop')`, 
                backgroundSize: 'cover',
                backgroundPosition: 'center 30%',
              }}
            />
            
            {/* Gradients to blend image and focus content */}
            <div className="absolute inset-0 z-1 bg-gradient-to-b from-[#051109]/20 via-[#051109]/70 to-[#051109] pointer-events-none h-[75vh]" />
            <div className="absolute inset-0 z-1 bg-gradient-to-t from-[#051109] via-[#051109]/95 to-transparent pointer-events-none h-[50vh] top-[20vh]" />
            <div className="absolute inset-0 z-1 bg-[#051109]/40 backdrop-blur-[1px] pointer-events-none" />

            {/* Main Content Area */}
            <div className="relative z-10 w-full max-w-md flex flex-col items-center px-7 pb-10 pt-4 min-h-screen">
              
              {/* Top Badge: Uraba Market */}
              <motion.div 
                initial={{ y: -50, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                className="bg-[#0A1D11]/90 backdrop-blur-xl border border-white/10 rounded-full pl-2.5 pr-5 py-2 flex items-center gap-3 mb-24 shadow-2xl mt-2"
              >
                <div className="w-7 h-7 bg-[#2D7A3E] rounded-full flex items-center justify-center">
                  <Leaf className="w-4 h-4 text-[#A7F3D0]" />
                </div>
                <span className="text-[15px] font-bold text-white tracking-wide">Urabá Market</span>
              </motion.div>

              {/* Central Logo: Tractor Icon */}
              <motion.div 
                initial={{ scale: 0.5, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ duration: 0.8, type: 'spring' }}
                className="w-28 h-28 rounded-full border-[1.5px] border-[#76A75A]/60 flex items-center justify-center mb-10 relative"
              >
                <div className="absolute inset-0 rounded-full bg-[#76A75A]/20 blur-2xl" />
                <div className="bg-[#1A2F1F] w-[92px] h-[92px] rounded-full flex items-center justify-center border border-[#76A75A]/30">
                  <Tractor className="w-11 h-11 text-white" />
                </div>
              </motion.div>

              {/* Heading Section */}
              <div className="text-center mb-10">
                <motion.h1 
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="text-[34px] font-bold text-[#D1FAE5] mb-2 tracking-tight leading-none"
                >
                  ¡Bienvenido de nuevo!
                </motion.h1>
                <motion.p 
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="text-zinc-400 text-[15px] font-normal"
                >
                  Conectamos a comerciantes con el mundo
                </motion.p>
              </div>

              {/* Form Container */}
              <div className="w-full space-y-6 mb-8">
                {/* Email Input */}
                <div className="space-y-2">
                  <label className="text-[13px] font-bold text-white/90 ml-1">
                    Correo electrónico
                  </label>
                  <div className="relative">
                    <div className="absolute left-4 top-1/2 -translate-y-1/2 text-zinc-500">
                      <Mail className="w-5 h-5" />
                    </div>
                    <Input 
                      className="bg-[#0A1D11]/60 border-[#1F3D26] h-14 pl-12 text-white placeholder:text-zinc-600 focus-visible:ring-1 focus-visible:ring-[#76A75A] rounded-2xl border-opacity-60"
                      placeholder="tuemail@ejemplo.com"
                    />
                  </div>
                </div>

                {/* Password Input */}
                <div className="space-y-2">
                  <div className="flex justify-between items-center px-1">
                    <label className="text-[13px] font-bold text-white/90">
                      Contraseña
                    </label>
                    <button className="text-[#76A75A] text-[13px] font-bold hover:brightness-125">
                      ¿Olvidaste tu contraseña?
                    </button>
                  </div>
                  <div className="relative">
                    <div className="absolute left-4 top-1/2 -translate-y-1/2 text-zinc-500">
                      <Lock className="w-5 h-5" />
                    </div>
                    <Input 
                      type="password"
                      className="bg-[#0A1D11]/60 border-[#1F3D26] h-14 pl-12 pr-12 text-white placeholder:text-zinc-600 focus-visible:ring-1 focus-visible:ring-[#76A75A] rounded-2xl border-opacity-60"
                      placeholder="........"
                    />
                    <button className="absolute right-4 top-1/2 -translate-y-1/2 text-zinc-500">
                      <Eye className="w-5 h-5" />
                    </button>
                  </div>
                </div>

                {/* Login Button */}
                <Button 
                  onClick={() => setCurrentScreen('profile-setup')}
                  className="w-full h-15 bg-gradient-to-r from-[#5E9146] to-[#76A75A] hover:opacity-90 text-white font-bold rounded-full text-[17px] flex items-center justify-center gap-3 shadow-xl transition-all"
                >
                  Ingresar al Marketplace
                  <ArrowRight className="w-5 h-5" />
                </Button>

                {/* Divider */}
                <div className="flex items-center gap-4 py-1">
                  <div className="flex-1 h-[1px] bg-zinc-800/60" />
                  <span className="text-zinc-600 text-[11px] font-bold uppercase tracking-widest whitespace-nowrap">o continúa con</span>
                  <div className="flex-1 h-[1px] bg-zinc-800/60" />
                </div>

                {/* Google Sign In */}
                <Button variant="outline" className="w-full h-14 bg-transparent border-[#1F3D26] hover:bg-white/5 text-white font-bold rounded-2xl flex items-center justify-center gap-3 border opacity-80 font-sans">
                  <svg className="w-5 h-5" viewBox="0 0 24 24">
                    <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4" />
                    <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
                    <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05" />
                    <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" />
                  </svg>
                  Continuar con Google
                </Button>

                {/* Registration Footer */}
                <div className="text-center pt-2">
                  <span className="text-zinc-500 text-[15px]">¿Aún no vendes con nosotros? </span>
                  <button 
                    onClick={() => setCurrentScreen('register')}
                    className="text-[#76A75A] font-bold text-[15px] hover:underline"
                  >
                    Regístrate
                  </button>
                </div>
              </div>

              {/* Benefits Card */}
              <motion.div 
                initial={{ y: 30, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                transition={{ delay: 0.5 }}
                className="w-full bg-[#0A1D11]/60 border border-white/10 rounded-[28px] p-6 mb-4 backdrop-blur-md"
              >
                <div className="grid grid-cols-3 gap-2">
                  <div className="flex flex-col items-center">
                    <div className="w-12 h-12 rounded-full bg-white/5 flex items-center justify-center mb-3">
                      <ShieldCheck className="w-6 h-6 text-[#76A75A]" />
                    </div>
                    <span className="text-[11px] font-bold text-white mb-0.5">Seguro</span>
                    <p className="text-[10px] text-zinc-500 text-center leading-tight">Tus datos están protegidos</p>
                  </div>
                  <div className="flex flex-col items-center">
                    <div className="w-12 h-12 rounded-full bg-white/5 flex items-center justify-center mb-3">
                      <Leaf className="w-6 h-6 text-[#76A75A]" />
                    </div>
                    <span className="text-[11px] font-bold text-white mb-0.5">100% Local</span>
                    <p className="text-[10px] text-zinc-500 text-center leading-tight whitespace-nowrap">Apoyamos lo nuestro</p>
                  </div>
                  <div className="flex flex-col items-center">
                    <div className="w-12 h-12 rounded-full bg-white/5 flex items-center justify-center mb-3">
                      <Truck className="w-6 h-6 text-[#76A75A]" />
                    </div>
                    <span className="text-[11px] font-bold text-white mb-0.5">Conectamos</span>
                    <p className="text-[10px] text-zinc-500 text-center leading-tight">Urabá con el mundo</p>
                  </div>
                </div>
              </motion.div>
            </div>
          </motion.div>
        )}
        {currentScreen === 'register' && (
          <motion.div
            key="register"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.3 }}
            className="w-full flex flex-col items-center"
          >
            {/* Background Layer: Vibrant Veggies Image */}
            <div 
              className="absolute top-0 inset-x-0 h-[50vh] z-0"
              style={{
                backgroundImage: `url('https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=2574&auto=format&fit=crop')`, 
                backgroundSize: 'cover',
                backgroundPosition: 'center 40%',
              }}
            />
            
            {/* Smooth Gradients to blend image without lines */}
            <div className="absolute inset-0 z-1 bg-gradient-to-b from-[#051109]/20 via-[#051109]/70 to-[#051109] pointer-events-none h-[75vh]" />
            <div className="absolute inset-0 z-1 bg-gradient-to-t from-[#051109] via-[#051109]/95 to-transparent pointer-events-none h-[50vh] top-[20vh]" />
            <div className="absolute inset-0 z-1 bg-[#051109]/40 backdrop-blur-[1px] pointer-events-none" />

            {/* Main Content Area */}
            <div className="relative z-10 w-full max-w-md flex flex-col items-center px-7 pb-10 pt-4 flex-1">
              
              {/* Back Button */}
              <div className="w-full flex justify-start mb-4">
                <button 
                  onClick={() => setCurrentScreen('login')}
                  className="w-11 h-11 rounded-full bg-black/40 backdrop-blur-xl flex items-center justify-center border border-white/20 hover:bg-black/60 transition-all shadow-lg"
                >
                  <ChevronLeft className="w-7 h-7 text-white" />
                </button>
              </div>

              {/* Central Logo: User Plus Icon */}
              <motion.div 
                initial={{ scale: 0.5, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ duration: 0.8, type: 'spring' }}
                className="w-28 h-28 rounded-full border-[1.5px] border-[#76A75A]/60 flex items-center justify-center mb-6 relative"
              >
                <div className="absolute inset-0 rounded-full bg-[#76A75A]/25 blur-3xl" />
                <div className="bg-[#1A2F1F] w-[90px] h-[90px] rounded-full flex items-center justify-center border border-[#76A75A]/40 shadow-inner">
                  <UserPlus className="w-10 h-10 text-white" strokeWidth={1.5} />
                </div>
              </motion.div>

              {/* Heading Section */}
              <div className="text-center mb-8">
                <motion.h1 
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="text-[38px] font-extrabold text-[#D1FAE5] mb-1 tracking-tight leading-none"
                >
                  Crear cuenta
                </motion.h1>
                <motion.p 
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="text-zinc-400 text-[17px] font-normal"
                >
                  Únete a la <span className="text-[#4ADE80] font-bold">comunidad</span> de Urabá.
                </motion.p>
              </div>

              {/* Form Container */}
              <div className="w-full space-y-4 mb-8">
                {/* Name Input */}
                <div className="relative group">
                  <div className="absolute left-4 top-1/2 -translate-y-1/2 z-10">
                    <div className="w-9 h-9 rounded-xl bg-[#06200D] flex items-center justify-center border border-[#103517]">
                      <User className="w-5 h-5 text-[#4ADE80]" />
                    </div>
                  </div>
                  <div className="flex flex-col bg-[#0A1D11]/70 border border-[#1F3D26] rounded-[22px] pl-16 pr-5 py-3.5 border-opacity-80 backdrop-blur-sm group-focus-within:border-[#4ADE80]/50 transition-all">
                    <span className="text-[11px] font-black text-white/40 uppercase tracking-[0.1em] mb-0.5">Nombre completo</span>
                    <Input 
                      className="bg-transparent border-none h-auto p-0 text-[16px] text-white placeholder:text-zinc-700 font-medium focus-visible:ring-0"
                      placeholder="Tu nombre completo"
                    />
                  </div>
                </div>

                {/* Email Input */}
                <div className="relative group">
                  <div className="absolute left-4 top-1/2 -translate-y-1/2 z-10">
                    <div className="w-9 h-9 rounded-xl bg-[#06200D] flex items-center justify-center border border-[#103517]">
                      <Mail className="w-5 h-5 text-[#4ADE80]" />
                    </div>
                  </div>
                  <div className="flex flex-col bg-[#0A1D11]/70 border border-[#1F3D26] rounded-[22px] pl-16 pr-5 py-3.5 border-opacity-80 backdrop-blur-sm group-focus-within:border-[#4ADE80]/50 transition-all">
                    <span className="text-[11px] font-black text-white/40 uppercase tracking-[0.1em] mb-0.5">Correo electrónico</span>
                    <Input 
                      className="bg-transparent border-none h-auto p-0 text-[16px] text-white placeholder:text-zinc-700 font-medium focus-visible:ring-0"
                      placeholder="tucorreo@ejemplo.com"
                    />
                  </div>
                </div>

                {/* Password Input */}
                <div className="relative group">
                  <div className="absolute left-4 top-1/2 -translate-y-1/2 z-10">
                    <div className="w-9 h-9 rounded-xl bg-[#06200D] flex items-center justify-center border border-[#103517]">
                      <Lock className="w-5 h-5 text-[#4ADE80]" />
                    </div>
                  </div>
                  <div className="flex flex-col bg-[#0A1D11]/70 border border-[#1F3D26] rounded-[22px] pl-16 pr-14 py-3.5 border-opacity-80 backdrop-blur-sm group-focus-within:border-[#4ADE80]/50 transition-all">
                    <span className="text-[11px] font-black text-white/40 uppercase tracking-[0.1em] mb-0.5">Contraseña</span>
                    <Input 
                      type="password"
                      className="bg-transparent border-none h-auto p-0 text-[16px] text-white placeholder:text-zinc-700 font-medium focus-visible:ring-0"
                      placeholder="........."
                    />
                  </div>
                  <button className="absolute right-5 top-1/2 -translate-y-1/2 text-zinc-600 hover:text-[#4ADE80] transition-colors">
                    <Eye className="w-5 h-5" />
                  </button>
                </div>

                {/* Confirm Password Input */}
                <div className="relative group">
                  <div className="absolute left-4 top-1/2 -translate-y-1/2 z-10">
                    <div className="w-9 h-9 rounded-xl bg-[#06200D] flex items-center justify-center border border-[#103517]">
                      <Lock className="w-5 h-5 text-[#4ADE80]" />
                    </div>
                  </div>
                  <div className="flex flex-col bg-[#0A1D11]/70 border border-[#1F3D26] rounded-[22px] pl-16 pr-14 py-3.5 border-opacity-80 backdrop-blur-sm group-focus-within:border-[#4ADE80]/50 transition-all">
                    <span className="text-[11px] font-black text-white/40 uppercase tracking-[0.1em] mb-0.5">Confirmar contraseña</span>
                    <Input 
                      type="password"
                      className="bg-transparent border-none h-auto p-0 text-[16px] text-white placeholder:text-zinc-700 font-medium focus-visible:ring-0"
                      placeholder="........."
                    />
                  </div>
                  <button className="absolute right-5 top-1/2 -translate-y-1/2 text-zinc-600 hover:text-[#4ADE80] transition-colors">
                    <Eye className="w-5 h-5" />
                  </button>
                </div>

                {/* Terms and Conditions */}
                <div className="w-full bg-[#0A1D11]/60 border border-[#1F3D26] rounded-[22px] px-5 py-4 flex items-center justify-between border-opacity-60 backdrop-blur-sm">
                  <div className="flex items-center gap-4">
                    <Checkbox id="terms" className="w-6 h-6 border-zinc-700 data-[state=checked]:bg-[#4ADE80] data-[state=checked]:border-[#4ADE80] rounded-md" />
                    <div className="flex flex-col">
                      <label htmlFor="terms" className="text-[14px] font-bold text-white cursor-pointer tracking-tight">Acepto los términos y condiciones</label>
                      <span className="text-[11px] text-zinc-500 font-medium">Cumplimiento Ley 527/1999 y Ley 1581/2012</span>
                    </div>
                  </div>
                  <ChevronRight className="w-5 h-5 text-zinc-600" />
                </div>

                {/* Create Account Button */}
                <div className="pt-2">
                  <Button 
                    onClick={() => setCurrentScreen('profile-setup')}
                    className="w-full h-16 bg-gradient-to-r from-[#97E752] via-[#4ADE80] to-[#22C55E] hover:brightness-110 text-[#052E16] font-black rounded-full text-[17px] flex items-center justify-between px-8 shadow-[0_15px_40px_rgba(34,197,94,0.25)] transition-all group active:scale-[0.98]"
                  >
                    <span className="uppercase tracking-[0.1em]">CREAR CUENTA</span>
                    <div className="w-11 h-11 bg-[#052E16] rounded-full flex items-center justify-center text-[#4ADE80] group-hover:translate-x-1.5 transition-transform">
                      <ArrowRight className="w-6 h-6" strokeWidth={2.5} />
                    </div>
                  </Button>
                </div>

                {/* Divider */}
                <div className="relative flex items-center justify-center py-4">
                  <div className="absolute w-full h-[1px] bg-zinc-800/60" />
                  <div className="relative w-3 h-3 rounded-full border border-zinc-800 bg-[#051109] shadow-sm" />
                </div>

                {/* Google Sign In */}
                <Button variant="outline" className="w-full h-15 bg-transparent border-zinc-800/80 hover:bg-white/5 text-white font-bold rounded-[22px] flex items-center justify-center gap-3 border opacity-100 font-sans text-[16px]">
                  <svg className="w-5 h-5" viewBox="0 0 24 24">
                    <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4" />
                    <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
                    <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05" />
                    <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" />
                  </svg>
                  Registrarse con Google
                </Button>
              </div>
            </div>

          </motion.div>
        )}

        {currentScreen === 'profile-setup' && (
          <motion.div
            key="profile-setup"
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            transition={{ duration: 0.4 }}
            className="w-full flex flex-col items-center"
          >
            {/* Background Layer: Market Store Image */}
            <div 
              className="absolute top-0 inset-x-0 h-[50vh] z-0"
              style={{
                backgroundImage: `url('https://images.unsplash.com/photo-1573481078935-b9605167e06b?q=80&w=2940&auto=format&fit=crop')`, 
                backgroundSize: 'cover',
                backgroundPosition: 'center 20%',
              }}
            />
            
            {/* Smooth Gradients to blend image without lines */}
            <div className="absolute inset-0 z-1 bg-gradient-to-b from-[#051109]/20 via-[#051109]/70 to-[#051109] pointer-events-none h-[75vh]" />
            <div className="absolute inset-0 z-1 bg-gradient-to-t from-[#051109] via-[#051109]/98 to-transparent pointer-events-none h-[50vh] top-[20vh]" />
            <div className="absolute inset-0 z-1 bg-[#051109]/40 backdrop-blur-[1px] pointer-events-none" />

            <div className="relative z-10 w-full max-w-md flex flex-col items-center px-6 pt-10 pb-8 flex-1">
              
              {/* Back Button */}
              <div className="w-full flex justify-start mb-2">
                <button 
                  onClick={() => setCurrentScreen('login')}
                  className="w-10 h-10 rounded-full bg-black/40 backdrop-blur-md flex items-center justify-center border border-white/10 hover:bg-black/60 transition-all"
                >
                  <ChevronLeft className="w-6 h-6 text-white" />
                </button>
              </div>

              {/* Profile Avatar Section */}
              <div className="relative mb-6">
                <div className="w-36 h-36 rounded-full border-2 border-emerald-500/50 p-2 flex items-center justify-center relative">
                  <div className="w-full h-full rounded-full bg-[#0A2D16] flex items-center justify-center border border-emerald-500/30 overflow-hidden shadow-[0_0_40px_rgba(16,185,129,0.25)]">
                    <User className="w-16 h-16 text-emerald-100/40" strokeWidth={1} />
                  </div>
                  <button className="absolute bottom-1 right-1 w-10 h-10 bg-emerald-500 rounded-full flex items-center justify-center border-4 border-[#051109] shadow-lg hover:scale-110 transition-transform">
                    <Camera className="w-5 h-5 text-white" />
                  </button>
                  
                  {/* Decorative Leaves */}
                  <motion.div 
                    animate={{ rotate: [0, 10, 0] }}
                    transition={{ duration: 4, repeat: Infinity }}
                    className="absolute -left-8 top-10 opacity-60"
                  >
                    <Leaf className="text-emerald-500 rotate-[-45deg]" size={36} />
                  </motion.div>
                  <motion.div 
                    animate={{ rotate: [0, -10, 0] }}
                    transition={{ duration: 5, repeat: Infinity, delay: 1 }}
                    className="absolute -right-10 top-4 opacity-60"
                  >
                    <Leaf className="text-emerald-500 rotate-[45deg]" size={42} />
                  </motion.div>
                </div>
              </div>

              {/* Headings */}
              <div className="text-center mb-8">
                <h1 className="text-[34px] font-black text-white leading-tight mb-1">
                  Completa tu <span className="text-[#4ADE80]">perfil</span>
                </h1>
                <p className="text-zinc-400 text-[16px] font-medium opacity-80">
                  Un último paso para comenzar
                </p>
              </div>

              {/* Form Section */}
              <div className="w-full space-y-6">
                <div className="space-y-2.5">
                  <div className="flex items-center gap-2 text-emerald-500 px-1">
                    <User className="w-4 h-4" />
                    <span className="text-[13px] font-black uppercase tracking-widest">Nombre completo</span>
                  </div>
                  <div className="relative group">
                    <div className="absolute left-4 top-1/2 -translate-y-1/2 text-zinc-600 group-focus-within:text-emerald-500 transition-colors">
                      <User className="w-5 h-5" />
                    </div>
                    <Input 
                      className="bg-[#0A1D11]/60 border-zinc-800 h-14 pl-12 text-white placeholder:text-zinc-600 focus-visible:ring-1 focus-visible:ring-emerald-500/50 rounded-2xl border-opacity-60 backdrop-blur-sm"
                      placeholder="¿Cómo te llamas?"
                    />
                  </div>
                </div>

                {/* Role Selection */}
                <div className="space-y-4">
                  <div className="flex items-center gap-2 text-emerald-500 px-1">
                    <Leaf className="w-4 h-4" />
                    <span className="text-[13px] font-black uppercase tracking-widest">¿Cómo usarás Urabá Market?</span>
                  </div>

                  <div className="space-y-3">
                    {/* Role: Comprador */}
                    <div 
                      onClick={() => setSelectedRole('comprador')}
                      className={`relative w-full p-4 rounded-3xl border transition-all cursor-pointer ${
                        selectedRole === 'comprador' 
                        ? 'bg-gradient-to-r from-[#166534] to-[#14532D] border-emerald-500/50 shadow-[0_10px_20px_rgba(22,101,52,0.3)]' 
                        : 'bg-[#0A1D11]/40 border-zinc-800 border-opacity-50 hover:bg-[#0A1D11]/60'
                      }`}
                    >
                      <div className="flex items-center gap-4">
                        <div className={`w-14 h-14 rounded-2xl flex items-center justify-center transition-colors ${
                          selectedRole === 'comprador' ? 'bg-white/10' : 'bg-emerald-950/40'
                        }`}>
                          <ShoppingBag className={`w-7 h-7 ${selectedRole === 'comprador' ? 'text-white' : 'text-emerald-500'}`} />
                        </div>
                        <div className="flex-1">
                          <h3 className="font-black text-[17px] text-white">Comprador</h3>
                          <p className={`text-[13px] leading-tight ${selectedRole === 'comprador' ? 'text-emerald-100/70' : 'text-zinc-500'}`}>
                            Encuentra productos frescos de la región
                          </p>
                        </div>
                        {selectedRole === 'comprador' ? (
                          <div className="w-7 h-7 bg-white rounded-full flex items-center justify-center shadow-sm">
                            <Check className="w-4 h-4 text-emerald-700" strokeWidth={5} />
                          </div>
                        ) : (
                          <ChevronRight className="w-6 h-6 text-zinc-700" />
                        )}
                      </div>
                    </div>

                    {/* Role: Comerciante */}
                    <div 
                      onClick={() => setSelectedRole('comerciante')}
                      className={`relative w-full p-4 rounded-3xl border transition-all cursor-pointer ${
                        selectedRole === 'comerciante' 
                        ? 'bg-gradient-to-r from-[#166534] to-[#14532D] border-emerald-500/50 shadow-[0_10px_20px_rgba(22,101,52,0.3)]' 
                        : 'bg-[#0A1D11]/40 border-zinc-800 border-opacity-50 hover:bg-[#0A1D11]/60'
                      }`}
                    >
                      <div className="flex items-center gap-4">
                        <div className={`w-14 h-14 rounded-2xl flex items-center justify-center transition-colors ${
                          selectedRole === 'comerciante' ? 'bg-white/10' : 'bg-emerald-950/40'
                        }`}>
                          <Store className={`w-7 h-7 ${selectedRole === 'comerciante' ? 'text-white' : 'text-emerald-500'}`} />
                        </div>
                        <div className="flex-1">
                          <h3 className="font-black text-[17px] text-white">Comerciante</h3>
                          <p className={`text-[13px] leading-tight ${selectedRole === 'comerciante' ? 'text-emerald-100/70' : 'text-zinc-500'}`}>
                            Vende y distribuye productos locales
                          </p>
                        </div>
                        {selectedRole === 'comerciante' ? (
                          <div className="w-7 h-7 bg-white rounded-full flex items-center justify-center shadow-sm">
                            <Check className="w-4 h-4 text-emerald-700" strokeWidth={5} />
                          </div>
                        ) : (
                          <ChevronRight className="w-6 h-6 text-zinc-700" />
                        )}
                      </div>
                    </div>

                    {/* Role: Productor */}
                    <div 
                      onClick={() => setSelectedRole('productor')}
                      className={`relative w-full p-4 rounded-3xl border transition-all cursor-pointer ${
                        selectedRole === 'productor' 
                        ? 'bg-gradient-to-r from-[#166534] to-[#14532D] border-emerald-500/50 shadow-[0_10px_20px_rgba(22,101,52,0.3)]' 
                        : 'bg-[#0A1D11]/40 border-zinc-800 border-opacity-50 hover:bg-[#0A1D11]/60'
                      }`}
                    >
                      <div className="flex items-center gap-4">
                        <div className={`w-14 h-14 rounded-2xl flex items-center justify-center transition-colors ${
                          selectedRole === 'productor' ? 'bg-white/10' : 'bg-emerald-950/40'
                        }`}>
                          <Tractor className={`w-7 h-7 ${selectedRole === 'productor' ? 'text-white' : 'text-emerald-500'}`} />
                        </div>
                        <div className="flex-1">
                          <h3 className="font-black text-[17px] text-white">Productor</h3>
                          <p className={`text-[13px] leading-tight ${selectedRole === 'productor' ? 'text-emerald-100/70' : 'text-zinc-500'}`}>
                            Vende directamente lo que cultivas
                          </p>
                        </div>
                        {selectedRole === 'productor' ? (
                          <div className="w-7 h-7 bg-white rounded-full flex items-center justify-center shadow-sm">
                            <Check className="w-4 h-4 text-emerald-700" strokeWidth={5} />
                          </div>
                        ) : (
                          <ChevronRight className="w-6 h-6 text-zinc-700" />
                        )}
                      </div>
                    </div>
                  </div>
                </div>

                {/* Benefits Mini */}
                <div className="grid grid-cols-3 gap-2 py-4 border-t border-white/5 mt-4">
                   <div className="flex flex-col items-center text-center">
                      <Leaf className="w-5 h-5 text-emerald-500 mb-1.5" />
                      <span className="text-[10px] font-black text-white/90 leading-tight">PRODUCTOS<br/>FRESCOS</span>
                      <p className="text-[9px] text-zinc-500 mt-1">de la región</p>
                   </div>
                   <div className="flex flex-col items-center text-center border-x border-white/5">
                      <ShieldCheck className="w-5 h-5 text-emerald-500 mb-1.5" />
                      <span className="text-[10px] font-black text-white/90 leading-tight">TRANSACCIONES<br/>SEGURAS</span>
                      <p className="text-[9px] text-zinc-500 mt-1">y confiables</p>
                   </div>
                   <div className="flex flex-col items-center text-center">
                      <Users className="w-5 h-5 text-emerald-500 mb-1.5" />
                      <span className="text-[10px] font-black text-white/90 leading-tight">APOYA NUESTRA<br/>COMUNIDAD</span>
                      <p className="text-[9px] text-zinc-500 mt-1">y productores</p>
                   </div>
                </div>

                {/* Final Button */}
                <Button 
                  onClick={() => setCurrentScreen('home')}
                  className="w-full h-16 bg-gradient-to-r from-[#97E752] via-[#4ADE80] to-[#22C55E] hover:brightness-110 text-[#052E16] font-black rounded-full text-[18px] flex items-center justify-between px-8 shadow-xl active:scale-[0.98] group mt-2"
                >
                   <div className="flex items-center gap-3">
                      <Rocket className="w-6 h-6 group-hover:-translate-y-1 transition-transform" />
                      <span>Comenzar ahora</span>
                   </div>
                   <ArrowRight className="w-6 h-6" />
                </Button>

                {/* Quick Security Footer */}
                <div className="flex items-center justify-center gap-2 py-2">
                   <ShieldCheck className="w-4 h-4 text-emerald-500/60" />
                   <span className="text-[11px] text-zinc-500 font-medium whitespace-nowrap">Es rápido, fácil y seguro</span>
                </div>
              </div>
            </div>
          </motion.div>
        )}
        {currentScreen === 'home' && (
          <motion.div
            key="home"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="w-full min-h-screen bg-[#051109] flex flex-col"
          >
            {/* Background Header Image */}
            <div className="absolute top-0 inset-x-0 h-[40vh] z-0 overflow-hidden">
                <div 
                    className="absolute inset-0 scale-110 blur-[2px] opacity-40"
                    style={{
                        backgroundImage: `url('https://images.unsplash.com/photo-1506477331477-33d5d8b3dc85?q=80&w=2834&auto=format&fit=crop')`, // Uraba coast feel
                        backgroundSize: 'cover',
                        backgroundPosition: 'center',
                    }}
                />
                <div className="absolute inset-0 bg-gradient-to-b from-[#051109]/40 via-[#051109]/80 to-[#051109]" />
            </div>

            {/* Sticky Header */}
            <div className="relative z-50 px-6 pt-12 pb-4 flex items-center justify-between">
                <button className="w-11 h-11 rounded-2xl bg-white/5 backdrop-blur-xl border border-white/10 flex items-center justify-center">
                    <Menu className="w-6 h-6 text-white" />
                </button>

                <div className="flex flex-col items-center">
                   <div className="flex items-center gap-2">
                      <Leaf className="w-6 h-6 text-[#4ADE80]" fill="#4ADE80" />
                      <span className="text-[20px] font-black text-white tracking-tight">Urabá <span className="text-[#4ADE80]">Market</span></span>
                   </div>
                   <div className="flex items-center gap-1 opacity-70">
                      <div className="w-1 h-1 rounded-full bg-[#4ADE80]" />
                      <span className="text-[10px] font-bold text-white uppercase tracking-widest">100% local, 100% Urabá 🍃</span>
                   </div>
                </div>

                <div className="flex items-center gap-3">
                   <div className="relative">
                      <button className="w-11 h-11 rounded-2xl bg-white/5 backdrop-blur-xl border border-white/10 flex items-center justify-center">
                          <ShoppingBag className="w-5 h-5 text-white" />
                      </button>
                      <div className="absolute -top-1 -right-1 w-5 h-5 bg-[#4ADE80] rounded-full border-2 border-[#051109] flex items-center justify-center">
                         <span className="text-[10px] font-black text-[#052E16]">2</span>
                      </div>
                   </div>
                   <button className="w-11 h-11 rounded-2xl bg-white/5 backdrop-blur-xl border border-white/10 flex items-center justify-center">
                      <Bell className="w-5 h-5 text-white" />
                   </button>
                   <div className="w-11 h-11 rounded-2xl border border-[#4ADE80]/30 p-0.5">
                      <img src="https://i.pravatar.cc/150?u=brayan" className="w-full h-full rounded-[14px] object-cover" alt="Profile" />
                   </div>
                </div>
            </div>

            {/* Scrollable Content */}
            <div className="relative z-10 flex-1 overflow-y-auto px-6 pb-24 scrollbar-hide">
                {/* Greeting */}
                <div className="mt-6 mb-6">
                    <h2 className="text-[32px] font-black text-white leading-tight">¡Hola, Brayan! 👋</h2>
                    <p className="text-zinc-400 text-[16px] mt-1 font-medium">
                       Apoya lo local y recibe lo mejor <br />
                       de Urabá <span className="text-[#4ADE80] font-bold">directo en tu hogar.</span>
                    </p>
                </div>

                {/* Search Bar */}
                <div className="flex items-center gap-3 mb-8">
                   <div className="flex-1 relative group">
                      <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-zinc-500 group-focus-within:text-[#4ADE80] transition-colors" />
                      <Input 
                        placeholder="Busca productos, servicios o tiendas..." 
                        className="bg-[#0A1D11]/60 border-zinc-800 h-14 pl-12 rounded-2xl text-white placeholder:text-zinc-600 focus-visible:ring-1 focus-visible:ring-[#4ADE80]/50"
                      />
                   </div>
                   <Button className="w-14 h-14 bg-[#103517] hover:bg-[#16421d] rounded-2xl border border-emerald-500/20 text-[#4ADE80]">
                      <SlidersHorizontal className="w-6 h-6" />
                      {/* Optional: label small if space permits? The mockup shows 'Filtros' next to icon sometimes */}
                   </Button>
                </div>

                {/* Categories */}
                <div className="flex items-center gap-4 overflow-x-auto pb-4 scrollbar-hide -mx-6 px-6">
                   {[
                      { icon: <Grid className="w-6 h-6" />, label: 'Todas', active: true },
                      { img: 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?q=80&w=150&auto=format&fit=crop', label: 'Frutas' },
                      { img: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?q=80&w=150&auto=format&fit=crop', label: 'Verduras' },
                      { img: 'https://images.unsplash.com/photo-1510674485131-dc88d98d9fe5?q=80&w=150&auto=format&fit=crop', label: 'Artesanías' },
                      { img: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=150&auto=format&fit=crop', label: 'Gastronomía' },
                   ].map((cat, i) => (
                      <div key={i} className="flex flex-col items-center gap-3 shrink-0">
                         <div className={`w-18 h-18 rounded-3xl flex items-center justify-center p-0.5 border ${cat.active ? 'border-[#4ADE80] bg-[#103517]' : 'border-zinc-800/40 bg-zinc-900/40'}`}>
                            {cat.icon ? (
                               <div className="text-[#4ADE80]">{cat.icon}</div>
                            ) : (
                               <img src={cat.img} className="w-full h-full rounded-[20px] object-cover opacity-80" alt={cat.label} />
                            )}
                         </div>
                         <span className={`text-[12px] font-black uppercase tracking-widest ${cat.active ? 'text-[#4ADE80]' : 'text-zinc-500'}`}>{cat.label}</span>
                      </div>
                   ))}
                </div>

                {/* Hero Banner Section */}
                <div className="mt-8 relative overflow-hidden rounded-[32px] group">
                   <div 
                      className="absolute inset-0 bg-cover bg-center transition-transform duration-700 group-hover:scale-110"
                      style={{ backgroundImage: `url('https://images.unsplash.com/photo-1488459711615-2287135baafb?q=80&w=1000&auto=format&fit=crop')` }}
                   />
                   <div className="absolute inset-0 bg-gradient-to-r from-black/90 via-black/40 to-transparent" />
                   
                   <div className="relative p-8 flex flex-col items-start min-h-[220px]">
                      <div className="flex items-center gap-2 bg-[#4ADE80] px-3 py-1.5 rounded-full mb-4">
                         <Leaf className="w-3.5 h-3.5 text-[#052E16]" fill="#052E16" />
                         <span className="text-[10px] font-black text-[#052E16] uppercase tracking-widest">100% Local</span>
                      </div>
                      <h2 className="text-[28px] font-black text-white leading-tight mb-2">
                         Productos frescos <br />
                         <span className="text-[#4ADE80]">de Urabá 🍃</span>
                      </h2>
                      <p className="text-zinc-300 text-[13px] font-medium max-w-[200px] mb-6 leading-snug">
                         Directos del campo a tu mesa. Apoya a nuestros productores.
                      </p>
                      <Button className="bg-[#4ADE80] hover:bg-[#3dbb6b] text-[#052E16] font-black px-6 rounded-full text-[14px] flex items-center gap-2 group/btn">
                         Ver productos
                         <ArrowRight className="w-4 h-4 group-hover/btn:translate-x-1 transition-transform" />
                      </Button>
                   </div>
                </div>

                {/* Slider indicator dots */}
                <div className="flex items-center justify-center gap-2 mt-4">
                   {[1,2,3,4].map((dot, i) => (
                      <div key={i} className={`h-1.5 rounded-full transition-all ${i === 0 ? 'w-6 bg-[#4ADE80]' : 'w-1.5 bg-zinc-800'}`} />
                   ))}
                </div>

                {/* Quick Actions Grid */}
                <div className="grid grid-cols-2 gap-3 mt-8">
                   <div className="bg-[#103517]/40 border border-emerald-500/10 rounded-3xl p-5 flex items-center gap-4 group cursor-pointer hover:border-[#4ADE80]/30 transition-all">
                      <div className="w-12 h-12 rounded-2xl bg-[#4ADE80] flex items-center justify-center text-[#052E16] shadow-[0_0_15px_rgba(74,222,128,0.3)]">
                         <Plus className="w-7 h-7" strokeWidth={3} />
                      </div>
                      <div>
                         <h4 className="text-[15px] font-black text-white leading-none">Publicar</h4>
                         <p className="text-[11px] text-zinc-500 mt-1">Vende tus productos</p>
                      </div>
                   </div>
                   <div className="bg-[#0A1D11]/60 border border-zinc-800/40 rounded-3xl p-5 flex items-center gap-4 group cursor-pointer hover:border-[#4ADE80]/30 transition-all">
                      <div className="w-12 h-12 rounded-2xl bg-[#103517] flex items-center justify-center text-[#4ADE80]">
                         <Store className="w-6 h-6" />
                      </div>
                      <div>
                         <h4 className="text-[15px] font-black text-white leading-none">Directorio</h4>
                         <p className="text-[11px] text-zinc-500 mt-1">Encuentra vendedores</p>
                      </div>
                   </div>
                   <div className="bg-[#0A1D11]/60 border border-zinc-800/40 rounded-3xl p-5 flex items-center gap-4 group cursor-pointer hover:border-[#4ADE80]/30 transition-all">
                      <div className="relative">
                         <div className="w-12 h-12 rounded-2xl bg-[#103517] flex items-center justify-center text-[#4ADE80]">
                            <MessageSquare className="w-6 h-6" />
                         </div>
                         <div className="absolute -top-1 -right-1 w-5 h-5 bg-[#4ADE80] rounded-full border-2 border-[#103517] flex items-center justify-center">
                            <span className="text-[10px] font-black text-[#052E16]">2</span>
                         </div>
                      </div>
                      <div>
                         <h4 className="text-[15px] font-black text-white leading-none">Mensajes</h4>
                         <p className="text-[11px] text-zinc-500 mt-1">Tus conversaciones</p>
                      </div>
                   </div>
                   <div className="bg-[#0A1D11]/60 border border-zinc-800/40 rounded-3xl p-5 flex items-center gap-4 group cursor-pointer hover:border-[#4ADE80]/30 transition-all">
                      <div className="w-12 h-12 rounded-2xl bg-[#4ADE80]/10 border border-[#4ADE80]/20 flex items-center justify-center text-[#4ADE80]">
                         <Sparkles className="w-6 h-6" />
                      </div>
                      <div>
                         <h4 className="text-[15px] font-black text-white leading-none">Asistente IA</h4>
                         <p className="text-[11px] text-zinc-500 mt-1">Pregunta lo que necesites</p>
                      </div>
                   </div>
                </div>

                {/* Nearby Section */}
                <div className="mt-10">
                   <div className="flex items-center justify-between mb-4 px-1">
                      <div className="flex items-center gap-2">
                         <MapPin className="w-5 h-5 text-[#4ADE80]" />
                         <h3 className="text-[18px] font-black text-white">Cerca de ti en Urabá</h3>
                      </div>
                      <button className="text-[13px] font-bold text-[#4ADE80]/80 flex items-center gap-1">
                         Ver todas <ChevronRight className="w-4 h-4" />
                      </button>
                   </div>
                   <div className="flex gap-4 overflow-x-auto pb-4 scrollbar-hide -mx-6 px-6">
                      {[
                        { img: 'https://images.unsplash.com/photo-1560493676-04071c5f467b?q=80&w=300&auto=format&fit=crop', name: 'Finca El Paraíso', loc: 'Turbo, Antioquia', dist: '1.2 km' },
                        { img: 'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?q=80&w=300&auto=format&fit=crop', name: 'Plátanos del Darién', loc: 'Apartadó, Antioquia', dist: '2.4 km' },
                        { img: 'https://images.unsplash.com/photo-1587334274328-64186a80aeee?q=80&w=300&auto=format&fit=crop', name: 'Cacao Urabá', loc: 'Chigorodó, Antioquia', dist: '3.1 km' },
                      ].map((shop, i) => (
                        <div key={i} className="min-w-[200px] bg-[#0A1D11]/40 border border-zinc-800/40 rounded-[28px] overflow-hidden group cursor-pointer hover:border-[#4ADE80]/20 transition-all">
                           <div className="h-28 overflow-hidden relative">
                              <img src={shop.img} className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" alt={shop.name} />
                              <div className="absolute bottom-2 left-2 bg-black/60 backdrop-blur-md px-2 py-1 rounded-full border border-white/5">
                                 <span className="text-[10px] font-black text-[#4ADE80] uppercase tracking-tighter">{shop.dist}</span>
                              </div>
                           </div>
                           <div className="p-4">
                              <h4 className="text-[15px] font-black text-white truncate">{shop.name}</h4>
                              <p className="text-[11px] text-zinc-500 font-medium mt-1 truncate">{shop.loc}</p>
                           </div>
                        </div>
                      ))}
                   </div>
                </div>

                {/* Featured Products Section */}
                <div className="mt-8">
                   <div className="flex items-center justify-between mb-6 px-1">
                      <div className="flex items-center gap-2">
                         <Rocket className="w-5 h-5 text-[#4ADE80]" />
                         <h3 className="text-[18px] font-black text-white">Productos destacados</h3>
                      </div>
                      <button className="text-[13px] font-bold text-[#4ADE80]/80 flex items-center gap-1">
                         Ver todas <ChevronRight className="w-4 h-4" />
                      </button>
                   </div>
                   
                   <div className="grid grid-cols-2 gap-4">
                      {[
                        { img: 'https://images.unsplash.com/photo-1591117207239-786cb4179767?q=80&w=400&auto=format&fit=crop', name: 'Papa de Segunda', price: '$120.000', cat: 'Verduras', unit: 'por bulto', rating: '4.8 (32)' },
                        { img: 'https://images.unsplash.com/photo-1528825838466-7ad31018591d?q=80&w=400&auto=format&fit=crop', name: 'Banano Criollo', price: '$80.000', cat: 'Frutas', unit: 'por racimo', rating: '4.9 (18)' },
                        { img: 'https://images.unsplash.com/photo-1486887396153-fa4163ad65b3?q=80&w=400&auto=format&fit=crop', name: 'Queso Costeño', price: '$28.000', cat: 'Lácteos', unit: 'por libra', rating: '4.7 (26)' },
                        { img: 'https://images.unsplash.com/photo-1590740003058-292f75470129?q=80&w=400&auto=format&fit=crop', name: 'Canasto en Bejuco', price: '$45.000', cat: 'Artesanías', unit: 'por unidad', rating: '5.0 (14)' },
                      ].map((item, i) => (
                        <div key={i} className="bg-[#0A1D11]/40 border border-zinc-800/40 rounded-[32px] overflow-hidden group cursor-pointer hover:border-[#4ADE80]/20 transition-all flex flex-col">
                           <div className="h-36 relative overflow-hidden">
                              <img src={item.img} className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" alt={item.name} />
                              <button className="absolute top-3 right-3 w-9 h-9 rounded-full bg-black/40 backdrop-blur-md flex items-center justify-center border border-white/5 text-white hover:text-red-500 transition-colors">
                                 <Heart className="w-4.5 h-4.5" />
                              </button>
                              <div className="absolute bottom-3 left-3 bg-[#4ADE80]/90 backdrop-blur-md px-3 py-1 rounded-full">
                                 <span className="text-[10px] font-black text-[#052E16] uppercase tracking-wider">{item.cat}</span>
                              </div>
                           </div>
                           <div className="p-4 flex-1 flex flex-col">
                              <h4 className="text-[15px] font-black text-white leading-tight mb-1">{item.name}</h4>
                              <div className="flex items-baseline gap-1 mt-auto">
                                 <span className="text-[16px] font-black text-[#4ADE80]">{item.price}</span>
                                 <span className="text-[10px] text-zinc-500 font-bold">{item.unit}</span>
                              </div>
                              <div className="flex items-center justify-between mt-3">
                                 <div className="flex items-center gap-1">
                                    <Star className="w-3.5 h-3.5 text-yellow-500 fill-yellow-500" />
                                    <span className="text-[11px] font-bold text-white/80">{item.rating}</span>
                                 </div>
                                 <button className="w-9 h-9 bg-[#103517] rounded-full flex items-center justify-center text-[#4ADE80] border border-emerald-500/20 hover:scale-110 transition-transform">
                                    <Plus className="w-5 h-5" />
                                 </button>
                              </div>
                           </div>
                        </div>
                      ))}
                   </div>
                </div>

                {/* Footnote Benefits */}
                <div className="mt-12 bg-white/5 rounded-[32px] p-6 border border-white/5 space-y-4">
                   <div className="flex items-center gap-4">
                      <div className="w-12 h-12 rounded-2xl bg-emerald-950/40 flex items-center justify-center text-emerald-500">
                         <Leaf className="w-6 h-6" />
                      </div>
                      <div>
                         <h5 className="text-[14px] font-black text-white">Apoya lo local</h5>
                         <p className="text-[11px] text-zinc-500 leading-tight">Fortalece nuestra región</p>
                      </div>
                   </div>
                   <div className="flex items-center gap-4 border-t border-white/5 pt-4">
                      <div className="w-12 h-12 rounded-2xl bg-emerald-950/40 flex items-center justify-center text-emerald-500">
                         <ShieldCheck className="w-6 h-6" />
                      </div>
                      <div>
                         <h5 className="text-[14px] font-black text-white">Pago seguro</h5>
                         <p className="text-[11px] text-zinc-500 leading-tight">Transacciones protegidas</p>
                      </div>
                   </div>
                </div>

                {/* Security Badge */}
                <div className="flex items-center justify-center gap-2 py-8 opacity-40">
                   <ShieldCheck className="w-4 h-4" />
                   <span className="text-[11px] font-bold uppercase tracking-widest text-zinc-500">Es rápido, fácil y seguro</span>
                </div>
            </div>

            {/* Bottom Tab Navigation */}
            <div className="fixed bottom-0 inset-x-0 h-24 bg-[#051109]/90 backdrop-blur-2xl border-t border-white/5 px-8 pt-2 pb-8 flex items-center justify-between z-[100]">
                <div className="flex flex-col items-center gap-1 group cursor-pointer transition-all">
                   <div className="relative">
                      <div className="absolute -inset-2 bg-[#4ADE80]/10 rounded-full blur-lg opacity-100" />
                      <Home className="w-7 h-7 text-[#4ADE80] relative z-10" />
                   </div>
                   <span className="text-[11px] font-black text-[#4ADE80] uppercase tracking-widest relative z-10">Inicio</span>
                </div>
                <div className="flex flex-col items-center gap-1 opacity-40 hover:opacity-100 transition-all cursor-pointer">
                   <Search className="w-7 h-7 text-white" />
                   <span className="text-[11px] font-black text-white uppercase tracking-widest">Explorar</span>
                </div>
                <div className="flex flex-col items-center gap-1 opacity-40 hover:opacity-100 transition-all cursor-pointer">
                   <Heart className="w-7 h-7 text-white" />
                   <span className="text-[11px] font-black text-white uppercase tracking-widest">Favoritos</span>
                </div>
                <div className="flex flex-col items-center gap-1 opacity-40 hover:opacity-100 transition-all cursor-pointer">
                   <div className="relative">
                      <ShoppingBag className="w-7 h-7 text-white" />
                      <div className="absolute -top-1.5 -right-1.5 w-4.5 h-4.5 bg-[#4ADE80] rounded-full border-2 border-[#051109] flex items-center justify-center">
                         <span className="text-[9px] font-black text-[#052E16]">2</span>
                      </div>
                   </div>
                   <span className="text-[11px] font-black text-white uppercase tracking-widest">Pedidos</span>
                </div>
                <div className="flex flex-col items-center gap-1 opacity-40 hover:opacity-100 transition-all cursor-pointer">
                   <User className="w-7 h-7 text-white" />
                   <span className="text-[11px] font-black text-white uppercase tracking-widest">Perfil</span>
                </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Decorative Foliage at the very bottom */}
      <div className="absolute bottom-[-10px] left-0 right-0 h-16 flex items-end justify-center pointer-events-none opacity-20 gap-4 overflow-hidden">
        {[...Array(5)].map((_, i) => (
           <Leaf key={i} className={`text-[#2D7A3E] transform ${i % 2 === 0 ? 'scale-150 rotate-12' : 'scale-125 -rotate-12'}`} size={40} />
        ))}
      </div>
    </div>
  );
}

