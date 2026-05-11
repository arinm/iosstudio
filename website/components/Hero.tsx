"use client";

import { motion } from "framer-motion";
import Image from "next/image";
import { appStoreUrl } from "@/lib/links";

export default function Hero() {
  return (
    <section className="relative min-h-screen flex flex-col items-center justify-center px-6 pt-16 overflow-hidden">
      {/* Subtle radial glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[600px] bg-indigo-500/5 rounded-full blur-[120px] pointer-events-none" />

      <div className="relative z-10 flex flex-col lg:flex-row items-center gap-12 lg:gap-20 max-w-6xl w-full">
        {/* Text content */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: "easeOut" }}
          className="text-center lg:text-left flex-1"
        >
          <h1 className="text-5xl sm:text-6xl md:text-7xl lg:text-7xl font-bold tracking-tight leading-[1.05]">
            Your iPhone Lock Screen,
            <br />
            <span className="gradient-text">on autopilot.</span>
          </h1>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="mt-6 text-lg md:text-xl text-white/50 max-w-xl leading-relaxed"
          >
            Calendar, top 3, todos, countdowns - a fresh wallpaper saved to
            Photos every morning via Apple Shortcuts. Plus an interactive
            widget to check todos right from your Home Screen.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.4 }}
            className="mt-10 flex flex-col sm:flex-row gap-4 justify-center lg:justify-start"
          >
            <a
              href={appStoreUrl("hero")}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center gap-3 px-8 py-4 rounded-full bg-white/10 border border-white/15 text-white font-medium text-base hover:bg-white/15 transition-all duration-300 backdrop-blur-sm"
            >
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
              </svg>
              Download on the App Store
            </a>
          </motion.div>
        </motion.div>

        {/* Phone mockup with screenshot */}
        <motion.div
          initial={{ opacity: 0, y: 50, scale: 0.95 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ duration: 1, delay: 0.3, ease: "easeOut" }}
          className="relative flex-shrink-0"
        >
          {/* Glow behind phone */}
          <div className="absolute -inset-16 bg-indigo-500/20 rounded-full blur-[120px] pointer-events-none" />
          <div className="absolute -inset-8 bg-purple-500/10 rounded-full blur-[80px] pointer-events-none" />

          {/* Phone frame */}
          <div className="relative w-[280px] h-[572px] sm:w-[300px] sm:h-[612px]">
            {/* Outer frame */}
            <div className="absolute inset-0 rounded-[52px] bg-gradient-to-b from-gray-700 via-gray-800 to-gray-900 p-[3px]">
              <div className="w-full h-full rounded-[49px] bg-black overflow-hidden relative">
                {/* Dynamic Island — hidden when using real screenshot that already includes it */}
                {/* <div className="absolute top-3 left-1/2 -translate-x-1/2 w-[100px] h-[28px] bg-black rounded-full z-20" /> */}

                {/* Screenshot image - replace this with real screenshot */}
                <Image
                  src="/screenshots/preview-photo-wallpaper.png"
                  alt="Lock Screen Studio - wallpaper preview"
                  fill
                  className="object-fill"
                  sizes="300px"
                  priority
                />

                {/* Fallback gradient if image not found */}
                <div className="absolute inset-0 bg-gradient-to-b from-indigo-950 via-indigo-900/80 to-slate-950 -z-10">
                  {/* Fallback content */}
                  <div className="flex flex-col items-center pt-16 px-6">
                    <p className="text-[11px] font-medium text-white/60 tracking-wide">
                      Monday, March 22
                    </p>
                    <p className="text-[68px] font-thin text-white tracking-tight leading-none mt-1">
                      09:41
                    </p>

                    <div className="w-full mt-8 space-y-5 px-2">
                      {/* Agenda panel */}
                      <div className="space-y-1">
                        <p className="text-[7px] font-semibold text-white/40 uppercase tracking-[2px]">
                          Agenda
                        </p>
                        <p className="text-[9px] text-indigo-400 font-medium leading-relaxed">
                          09:00 Team Standup
                        </p>
                        <p className="text-[9px] text-white/70 leading-relaxed">
                          10:30 Design Review
                        </p>
                        <p className="text-[9px] text-white/70 leading-relaxed">
                          14:00 Sprint Planning
                        </p>
                      </div>

                      {/* Top 3 panel */}
                      <div className="space-y-1">
                        <p className="text-[7px] font-semibold text-white/40 uppercase tracking-[2px]">
                          Top 3
                        </p>
                        <p className="text-[9px] text-indigo-400 font-medium leading-relaxed">
                          1. Ship v1.0
                        </p>
                        <p className="text-[9px] text-white/70 leading-relaxed">
                          2. Review pull requests
                        </p>
                        <p className="text-[9px] text-white/70 leading-relaxed">
                          3. Gym at 6pm
                        </p>
                      </div>

                      {/* To-Do panel */}
                      <div className="space-y-1">
                        <p className="text-[7px] font-semibold text-white/40 uppercase tracking-[2px]">
                          To-Do
                        </p>
                        <p className="text-[9px] text-white/30 leading-relaxed">
                          &#9745; Reply to emails
                        </p>
                        <p className="text-[9px] text-white/70 leading-relaxed">
                          &#9744; Prepare presentation
                        </p>
                        <p className="text-[9px] text-white/70 leading-relaxed">
                          &#9744; Book flight tickets
                        </p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Home indicator */}
                <div className="absolute bottom-2 left-1/2 -translate-x-1/2 z-20">
                  <div className="w-28 h-1 bg-white/20 rounded-full" />
                </div>
              </div>
            </div>

            {/* Side button (power) */}
            <div className="absolute -right-[2px] top-[120px] w-[3px] h-[60px] bg-gray-700 rounded-r-sm" />
            {/* Volume buttons */}
            <div className="absolute -left-[2px] top-[100px] w-[3px] h-[28px] bg-gray-700 rounded-l-sm" />
            <div className="absolute -left-[2px] top-[140px] w-[3px] h-[45px] bg-gray-700 rounded-l-sm" />
            <div className="absolute -left-[2px] top-[195px] w-[3px] h-[45px] bg-gray-700 rounded-l-sm" />
          </div>

          {/* Floating badge */}
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 1, duration: 0.5 }}
            className="absolute -bottom-4 -right-4 bg-indigo-600 text-white text-xs font-semibold px-3 py-1.5 rounded-full shadow-lg shadow-indigo-500/30"
          >
            Fresh daily, one tap
          </motion.div>
        </motion.div>
      </div>

      {/* Scroll indicator */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.2 }}
        className="relative z-10 mt-16"
      >
        <motion.div
          animate={{ y: [0, 8, 0] }}
          transition={{ duration: 1.5, repeat: Infinity }}
          className="w-6 h-10 rounded-full border-2 border-white/20 flex justify-center pt-2"
        >
          <div className="w-1 h-2 rounded-full bg-white/40" />
        </motion.div>
      </motion.div>
    </section>
  );
}
