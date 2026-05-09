"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";

const sampleTodos = [
  { text: "Reply to Sarah's email", done: true },
  { text: "Review pull request", done: false },
  { text: "Gym at 6pm", done: false },
];

export default function FeatureWidget() {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  return (
    <section id="widget" className="py-32 px-6 relative overflow-hidden" ref={ref}>
      <div className="max-w-6xl mx-auto">
        {/* Headline */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.7 }}
          className="text-center mb-16"
        >
          <span className="inline-block mb-4 px-3 py-1 rounded-full text-xs font-semibold text-indigo-300 bg-indigo-500/10 border border-indigo-500/20">
            NEW IN 1.1
          </span>
          <h2 className="text-4xl sm:text-5xl md:text-6xl font-bold tracking-tight leading-tight">
            Check todos done
            <br />
            <span className="gradient-text">from your Home Screen.</span>
          </h2>
          <p className="mt-6 text-lg text-white/50 max-w-lg mx-auto">
            One tap on the interactive widget marks a todo done — without ever
            opening the app. Built on iOS 17 App Intents and synced via App
            Group SwiftData.
          </p>
        </motion.div>

        {/* Widget mockup */}
        <div className="relative flex justify-center items-center">
          {/* Glow */}
          <div className="absolute w-[420px] h-[420px] bg-indigo-500/15 rounded-full blur-[120px] pointer-events-none" />

          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={isInView ? { opacity: 1, scale: 1 } : {}}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="relative grid grid-cols-1 md:grid-cols-2 gap-10 items-center"
          >
            {/* Widget tile */}
            <div className="flex justify-center">
              <div className="w-[260px] h-[260px] rounded-[40px] bg-white/95 dark:bg-white/95 p-5 shadow-2xl shadow-indigo-500/20 border border-white/10">
                <div className="h-full flex flex-col gap-2">
                  <div className="flex items-center gap-2 mb-1">
                    <svg
                      width="14"
                      height="14"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="rgb(79, 70, 229)"
                      strokeWidth="2.5"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <path d="M9 11l3 3L22 4" />
                      <path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11" />
                    </svg>
                    <span className="text-[13px] font-bold text-gray-500 uppercase tracking-wider">
                      Today
                    </span>
                  </div>

                  {sampleTodos.map((todo, i) => (
                    <motion.div
                      key={i}
                      initial={{ opacity: 0, x: -8 }}
                      animate={isInView ? { opacity: 1, x: 0 } : {}}
                      transition={{
                        duration: 0.4,
                        delay: 0.4 + i * 0.12,
                      }}
                      className="flex items-center gap-2.5 py-1"
                    >
                      <div
                        className={`w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0 ${
                          todo.done
                            ? "bg-indigo-600"
                            : "border-2 border-gray-300"
                        }`}
                      >
                        {todo.done && (
                          <svg
                            width="11"
                            height="11"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="white"
                            strokeWidth="3.5"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          >
                            <path d="M20 6L9 17l-5-5" />
                          </svg>
                        )}
                      </div>
                      <span
                        className={`text-[14px] leading-tight ${
                          todo.done
                            ? "text-gray-400 line-through"
                            : "text-gray-900"
                        }`}
                      >
                        {todo.text}
                      </span>
                    </motion.div>
                  ))}
                </div>
              </div>
            </div>

            {/* Bullets */}
            <div className="space-y-6">
              {[
                {
                  title: "Tap to toggle",
                  body: "Mark anything done from the widget. No app launch, no animation delay.",
                },
                {
                  title: "Stays in sync",
                  body: "App and widget share the same SwiftData store via App Group, so changes appear everywhere instantly.",
                },
                {
                  title: "Two sizes",
                  body: "Small fits 3 todos, medium fits 6. Place it wherever you actually look.",
                },
              ].map((item, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, y: 16 }}
                  animate={isInView ? { opacity: 1, y: 0 } : {}}
                  transition={{ duration: 0.5, delay: 0.5 + i * 0.12 }}
                  className="flex gap-4"
                >
                  <div className="flex-shrink-0 w-8 h-8 rounded-full bg-indigo-500/15 border border-indigo-500/30 flex items-center justify-center text-indigo-300 font-semibold text-sm">
                    {i + 1}
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold text-white mb-1">
                      {item.title}
                    </h3>
                    <p className="text-white/50 leading-relaxed">{item.body}</p>
                  </div>
                </motion.div>
              ))}
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
