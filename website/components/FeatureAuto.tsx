"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";
import Image from "next/image";

const floatingIcons = [
  { icon: "M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z", x: -140, y: -80, delay: 0 },
  { icon: "M13 10V3L4 14h7v7l9-11h-7z", x: 140, y: -60, delay: 0.5 },
  { icon: "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z", x: -160, y: 80, delay: 1 },
  { icon: "M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10", x: 160, y: 100, delay: 1.5 },
  { icon: "M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15", x: -100, y: 160, delay: 2 },
];

export default function FeatureAuto() {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  return (
    <section id="features" className="py-32 px-6 overflow-hidden" ref={ref}>
      <div className="max-w-6xl mx-auto">
        {/* Headline */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.7 }}
          className="text-center mb-20"
        >
          <h2 className="text-4xl sm:text-5xl md:text-6xl font-bold tracking-tight leading-tight">
            Updates automatically.
            <br />
            No manual refresh.
          </h2>
          <p className="mt-6 text-lg text-white/50 max-w-lg mx-auto">
            Your wallpaper stays fresh using Apple Shortcuts — quietly in the
            background.
          </p>
        </motion.div>

        {/* Phone with floating icons */}
        <div className="relative flex justify-center items-center">
          {/* Glow behind phone */}
          <div className="absolute w-[400px] h-[400px] bg-indigo-500/10 rounded-full blur-[100px]" />

          {/* Floating icons */}
          {floatingIcons.map((item, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, scale: 0.5 }}
              animate={
                isInView ? { opacity: 1, scale: 1 } : {}
              }
              transition={{ duration: 0.6, delay: 0.3 + item.delay * 0.2 }}
              className={`absolute hidden md:flex items-center justify-center w-14 h-14 rounded-2xl bg-white/5 border border-white/10 backdrop-blur-sm ${
                i === 0
                  ? "animate-float"
                  : i === 1
                  ? "animate-float-delay-1"
                  : i === 2
                  ? "animate-float-delay-2"
                  : i === 3
                  ? "animate-float-delay-3"
                  : "animate-float-delay-4"
              }`}
              style={{
                left: `calc(50% + ${item.x}px)`,
                top: `calc(50% + ${item.y}px)`,
              }}
            >
              <svg
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="rgba(99, 102, 241, 0.7)"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d={item.icon} />
              </svg>
              {/* Glow */}
              <div className="absolute inset-0 rounded-2xl bg-indigo-500/10 blur-xl -z-10" />
            </motion.div>
          ))}

          {/* Center phone — real screenshot */}
          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={isInView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.2 }}
          >
            <div className="relative w-[280px] h-[580px] rounded-[42px] border-[2px] border-white/10 overflow-hidden shadow-2xl bg-black">
              <Image
                src="/screenshots/shortcuts-automation.png"
                alt="Daily auto-generate with Shortcuts"
                fill
                className="object-cover"
                sizes="280px"
              />
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
