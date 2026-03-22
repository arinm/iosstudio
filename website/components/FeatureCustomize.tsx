"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";
import Image from "next/image";

const features = [
  "13+ Built-in Templates",
  "Custom Themes & Gradients",
  "Configurable Panels",
  "Photo Backgrounds",
  "Shortcuts Automation",
];

export default function FeatureCustomize() {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  return (
    <section className="py-32 px-6" ref={ref}>
      <div className="max-w-6xl mx-auto grid md:grid-cols-2 gap-16 items-center">
        {/* Text side */}
        <motion.div
          initial={{ opacity: 0, x: -40 }}
          animate={isInView ? { opacity: 1, x: 0 } : {}}
          transition={{ duration: 0.7 }}
        >
          <span className="text-sm font-semibold tracking-widest uppercase text-indigo-400">
            Full Customizability
          </span>

          <h2 className="mt-4 text-4xl sm:text-5xl font-bold tracking-tight leading-tight">
            Make it unique.
            <br />
            Make it yours.
          </h2>

          <p className="mt-6 text-lg text-white/50 leading-relaxed">
            Choose any layout from the presets and customize it to your needs.
            Adjust panels, themes, colors, and backgrounds to create a dashboard
            that fits your style perfectly.
          </p>

          <ul className="mt-8 space-y-4">
            {features.map((feature, i) => (
              <motion.li
                key={feature}
                initial={{ opacity: 0, x: -20 }}
                animate={isInView ? { opacity: 1, x: 0 } : {}}
                transition={{ duration: 0.5, delay: 0.3 + i * 0.1 }}
                className="flex items-center gap-3"
              >
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="#6366f1"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M20 6L9 17l-5-5" />
                </svg>
                <span className="text-white/80 font-medium">{feature}</span>
              </motion.li>
            ))}
          </ul>
        </motion.div>

        {/* Phones side — real screenshots */}
        <motion.div
          initial={{ opacity: 0, x: 40 }}
          animate={isInView ? { opacity: 1, x: 0 } : {}}
          transition={{ duration: 0.7, delay: 0.2 }}
          className="relative flex justify-center items-center min-h-[500px]"
        >
          {/* Back phone (left) — theme picker photo */}
          <motion.div
            initial={{ opacity: 0, rotate: -6 }}
            animate={isInView ? { opacity: 0.7, rotate: -6 } : {}}
            transition={{ duration: 0.7, delay: 0.4 }}
            className="absolute -left-4 top-8 scale-90"
          >
            <div className="relative w-[200px] h-[433px] rounded-[32px] border-[2px] border-white/10 overflow-hidden shadow-2xl bg-black">
              <Image
                src="/screenshots/theme-picker-photo.png"
                alt="Theme picker with photo background"
                fill
                className="object-cover"
                sizes="200px"
              />
            </div>
          </motion.div>

          {/* Center phone — theme colors */}
          <div className="relative z-10">
            <div className="relative w-[220px] h-[476px] rounded-[36px] border-[2px] border-white/10 overflow-hidden shadow-2xl bg-black">
              <Image
                src="/screenshots/theme-picker-colors.png"
                alt="Theme customization with colors"
                fill
                className="object-cover"
                sizes="220px"
              />
            </div>
          </div>

          {/* Back phone (right) — add panel */}
          <motion.div
            initial={{ opacity: 0, rotate: 6 }}
            animate={isInView ? { opacity: 0.7, rotate: 6 } : {}}
            transition={{ duration: 0.7, delay: 0.5 }}
            className="absolute -right-4 top-8 scale-90"
          >
            <div className="relative w-[200px] h-[433px] rounded-[32px] border-[2px] border-white/10 overflow-hidden shadow-2xl bg-black">
              <Image
                src="/screenshots/add-panel-sheet.png"
                alt="Add panel options"
                fill
                className="object-cover"
                sizes="200px"
              />
            </div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
}
