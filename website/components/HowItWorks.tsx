"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";
import Image from "next/image";

const steps = [
  {
    number: "01",
    title: "Choose a Template",
    description:
      "Browse 13+ built-in templates designed for different lifestyles — students, professionals, fitness enthusiasts, and more.",
    screenshot: "/screenshots/gallery-templates.png",
  },
  {
    number: "02",
    title: "Customize Your Panels",
    description:
      "Toggle panels on or off, reorder them, tweak settings. Add agenda, priorities, to-dos, countdown, notes — whatever you need.",
    screenshot: "/screenshots/editor-today-dashboard.png",
  },
  {
    number: "03",
    title: "Generate & Apply",
    description:
      "Hit Generate to save the wallpaper to Photos, then apply as your Lock Screen. Pair with Apple Shortcuts so a fresh one lands in Photos every morning — one tap to apply.",
    screenshot: "/screenshots/export-screen.png",
  },
];

export default function HowItWorks() {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  return (
    <section id="how-it-works" className="py-32 px-6" ref={ref}>
      <div className="max-w-6xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.7 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl sm:text-5xl md:text-6xl font-bold tracking-tight">
            Set it up in minutes.
          </h2>
          <p className="mt-6 text-lg text-white/50 max-w-md mx-auto">
            Three simple steps to a smarter Lock Screen.
          </p>
        </motion.div>

        <div className="grid md:grid-cols-3 gap-6">
          {steps.map((step, i) => (
            <motion.div
              key={step.number}
              initial={{ opacity: 0, y: 40 }}
              animate={isInView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6, delay: i * 0.15 }}
              className="relative p-6 rounded-2xl bg-white/[0.03] border border-white/[0.06] hover:bg-white/[0.05] transition-all duration-300 group"
            >
              {/* Step number */}
              <span className="text-sm font-mono font-bold text-indigo-400/50">
                {step.number}
              </span>

              {/* Screenshot */}
              <div className="mt-4 relative w-full aspect-[9/16] max-h-[320px] rounded-xl overflow-hidden border border-white/10">
                <Image
                  src={step.screenshot}
                  alt={step.title}
                  fill
                  className="object-cover object-top"
                  sizes="(max-width: 768px) 100vw, 33vw"
                />
              </div>

              <h3 className="mt-5 text-xl font-bold text-white/90">
                {step.title}
              </h3>
              <p className="mt-3 text-sm text-white/40 leading-relaxed">
                {step.description}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
