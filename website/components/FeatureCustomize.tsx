"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";
import LockScreenMockup from "./LockScreenMockup";

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

        {/* Phones side */}
        <motion.div
          initial={{ opacity: 0, x: 40 }}
          animate={isInView ? { opacity: 1, x: 0 } : {}}
          transition={{ duration: 0.7, delay: 0.2 }}
          className="relative flex justify-center items-center min-h-[500px]"
        >
          {/* Back phone (left) */}
          <div className="absolute -left-4 top-8 -rotate-6 opacity-70 scale-90">
            <LockScreenMockup
              size="md"
              gradient="from-emerald-950 via-slate-950 to-black"
              dateText="Monday, February 23"
              timeText="09:41"
              panels={[
                {
                  title: "Countdown",
                  lines: [
                    { text: "15", accent: true },
                    { text: "days until Birthday", dim: true },
                  ],
                },
                {
                  title: "Note",
                  lines: [
                    { text: "Pick up the cake" },
                    { text: "Call mom by 5pm" },
                  ],
                },
              ]}
            />
          </div>

          {/* Center phone */}
          <div className="relative z-10">
            <LockScreenMockup
              size="md"
              gradient="from-indigo-950 via-indigo-900 to-slate-950"
              dateText="Monday, February 23"
              timeText="09:41"
              panels={[
                {
                  title: "Agenda",
                  lines: [
                    { text: "09:00  Team Standup", accent: true },
                    { text: "10:30  Design Review" },
                    { text: "12:00  Lunch with Alex" },
                    { text: "14:00  Sprint Planning" },
                  ],
                },
                {
                  title: "Top 3",
                  lines: [
                    { text: "1. Ship v1.0", accent: true },
                    { text: "2. Review pull requests" },
                    { text: "3. Gym at 6pm" },
                  ],
                },
              ]}
            />
          </div>

          {/* Back phone (right) */}
          <div className="absolute -right-4 top-8 rotate-6 opacity-70 scale-90">
            <LockScreenMockup
              size="md"
              gradient="from-rose-950 via-slate-950 to-black"
              dateText="Monday, February 23"
              timeText="09:41"
              panels={[
                {
                  title: "Meetings",
                  lines: [
                    { text: "09:00  Kickoff Call", accent: true },
                    { text: "11:00  Client Review" },
                    { text: "15:00  1:1 with Manager" },
                  ],
                },
              ]}
            />
          </div>
        </motion.div>
      </div>
    </section>
  );
}
