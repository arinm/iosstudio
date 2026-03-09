"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";

export default function CTA() {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  return (
    <section id="download" className="py-32 px-6 relative" ref={ref}>
      {/* Glow background */}
      <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
        <div className="w-[600px] h-[400px] bg-indigo-500/8 rounded-full blur-[120px]" />
      </div>

      <motion.div
        initial={{ opacity: 0, y: 40 }}
        animate={isInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7 }}
        className="relative z-10 text-center max-w-2xl mx-auto"
      >
        <h2 className="text-4xl sm:text-5xl md:text-6xl font-bold tracking-tight leading-tight">
          Your Lock Screen,
          <br />
          <span className="gradient-text">reimagined.</span>
        </h2>

        <p className="mt-6 text-lg text-white/50">
          Download for free and start building your personal dashboard today.
        </p>

        <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
          <a
            href="#"
            className="inline-flex items-center gap-3 px-8 py-4 rounded-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-base transition-all duration-300 glow-indigo"
          >
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="currentColor"
            >
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
            </svg>
            Download for Free
          </a>
        </div>

        <p className="mt-4 text-sm text-white/30">
          Free with optional Pro upgrade &middot; iOS 17+
        </p>
      </motion.div>
    </section>
  );
}
