"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";

const steps = [
  {
    number: "01",
    title: "Choose a Template",
    description:
      "Browse 13+ built-in templates designed for different lifestyles — students, professionals, fitness enthusiasts, and more.",
    icon: "M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z",
  },
  {
    number: "02",
    title: "Customize Your Panels",
    description:
      "Toggle panels on or off, reorder them, tweak settings. Add agenda, priorities, to-dos, countdown, notes — whatever you need.",
    icon: "M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4",
  },
  {
    number: "03",
    title: "Generate & Set",
    description:
      "Hit Generate, save to your Lock Screen. Or set up a Shortcut to auto-update every morning — zero effort after setup.",
    icon: "M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z",
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
              className="relative p-8 rounded-2xl bg-white/[0.03] border border-white/[0.06] hover:bg-white/[0.05] transition-all duration-300 group"
            >
              {/* Step number */}
              <span className="text-sm font-mono font-bold text-indigo-400/50">
                {step.number}
              </span>

              {/* Icon */}
              <div className="mt-4 w-12 h-12 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center group-hover:bg-indigo-500/15 transition-colors">
                <svg
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="#6366f1"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d={step.icon} />
                </svg>
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
