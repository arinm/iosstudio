"use client";

import { useState } from "react";
import { motion, useInView, AnimatePresence } from "framer-motion";
import { useRef } from "react";

const faqs = [
  {
    q: "Is Lock Screen Studio free?",
    a: "Yes! The core features are completely free — choose from several templates, customize panels, and generate wallpapers. Pro unlocks additional templates, gradient backgrounds, alternative app icons, and the ability to add unlimited panels.",
  },
  {
    q: "How does the wallpaper update each day?",
    a: "Lock Screen Studio integrates with Apple Shortcuts. You set up an automation that runs on a schedule you pick (e.g., 7:00 AM) — it generates a fresh wallpaper with your latest agenda and todos, saves it to Photos, and sends a notification. Tap the notification → Photos → Use as Wallpaper → Lock Screen. One tap to apply.",
  },
  {
    q: "Why isn't applying the wallpaper fully automatic?",
    a: "In iOS 26 Apple removed the Shortcuts action that lets third-party apps change your wallpaper directly. The fresh wallpaper still arrives in your Photos automatically every morning — you just tap once to set it. We're tracking iOS updates and will switch back to fully hands-free the moment Apple restores the capability.",
  },
  {
    q: "What iPhone models are supported?",
    a: "Lock Screen Studio supports all iPhones running iOS 17 or later. The app automatically adapts wallpaper dimensions to your specific device — from iPhone SE to iPhone 16 Pro Max.",
  },
  {
    q: "What's included in Pro?",
    a: "Pro gives you access to all templates, gradient backgrounds, alternative app icons, the ability to add unlimited custom panels to any template, and priority support. Available as a monthly or yearly subscription with a free trial.",
  },
  {
    q: "Can I use my own photos as backgrounds?",
    a: "Absolutely. You can pick any photo from your library as a wallpaper background. The app overlays your dashboard panels on top, so your favorite photo becomes a functional Lock Screen.",
  },
  {
    q: "Does it work with my calendar?",
    a: "Yes. Lock Screen Studio reads your Apple Calendar events and displays them in the Agenda panel. You grant calendar access once, and your schedule is always up to date on your Lock Screen.",
  },
];

function FAQItem({ q, a }: { q: string; a: string }) {
  const [open, setOpen] = useState(false);

  return (
    <button
      onClick={() => setOpen(!open)}
      className="w-full text-left p-6 rounded-2xl bg-white/[0.03] border border-white/[0.06] hover:bg-white/[0.05] transition-all duration-300"
    >
      <div className="flex items-center justify-between gap-4">
        <h3 className="font-semibold text-white/90">{q}</h3>
        <motion.svg
          animate={{ rotate: open ? 45 : 0 }}
          transition={{ duration: 0.2 }}
          width="20"
          height="20"
          viewBox="0 0 24 24"
          fill="none"
          stroke="rgba(255,255,255,0.4)"
          strokeWidth="2"
          className="flex-shrink-0"
        >
          <path d="M12 5v14M5 12h14" />
        </motion.svg>
      </div>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.3 }}
            className="overflow-hidden"
          >
            <p className="mt-4 text-sm text-white/40 leading-relaxed">{a}</p>
          </motion.div>
        )}
      </AnimatePresence>
    </button>
  );
}

export default function FAQ() {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  return (
    <section id="faq" className="py-32 px-6" ref={ref}>
      <div className="max-w-3xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.7 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl sm:text-5xl font-bold tracking-tight">
            Frequently Asked Questions
          </h2>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.7, delay: 0.2 }}
          className="space-y-3"
        >
          {faqs.map((faq) => (
            <FAQItem key={faq.q} q={faq.q} a={faq.a} />
          ))}
        </motion.div>
      </div>
    </section>
  );
}
