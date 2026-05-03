"use client";

import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { appStoreUrl } from "@/lib/links";

const navLinks = [
  { label: "Features", href: "#features" },
  { label: "How it works", href: "#how-it-works" },
  { label: "FAQ", href: "#faq" },
];

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 50);
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <motion.nav
      initial={{ y: -20, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ duration: 0.5 }}
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        scrolled
          ? "bg-black/70 backdrop-blur-xl border-b border-white/5"
          : "bg-transparent"
      }`}
    >
      <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
        {/* Logo */}
        <a href="#" className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-indigo-700 flex items-center justify-center shadow-lg shadow-indigo-500/20">
            <svg
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              {/* Phone body */}
              <rect x="5" y="2" width="14" height="20" rx="3" stroke="white" strokeWidth="1.5" />
              {/* Dynamic Island */}
              <rect x="9.5" y="3.5" width="5" height="1.5" rx="0.75" fill="white" fillOpacity="0.4" />
              {/* Dashboard lines */}
              <rect x="8" y="7" width="8" height="1.2" rx="0.6" fill="white" fillOpacity="0.9" />
              <rect x="8" y="9.5" width="5.5" height="1" rx="0.5" fill="white" fillOpacity="0.5" />
              <rect x="8" y="11.5" width="7" height="1" rx="0.5" fill="white" fillOpacity="0.5" />
              <rect x="8" y="13.5" width="4" height="1" rx="0.5" fill="white" fillOpacity="0.5" />
              {/* Accent dot */}
              <circle cx="16.5" y="9.5" cy="10" r="1" fill="#a5b4fc" />
              {/* Home indicator */}
              <rect x="9.5" y="19.5" width="5" height="1" rx="0.5" fill="white" fillOpacity="0.3" />
            </svg>
          </div>
          <span className="font-semibold text-sm text-white tracking-tight">
            Lock Screen Studio
          </span>
        </a>

        {/* Desktop links */}
        <div className="hidden md:flex items-center gap-8">
          {navLinks.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className="text-sm text-white/60 hover:text-white transition-colors"
            >
              {link.label}
            </a>
          ))}
        </div>

        {/* CTA */}
        <a
          href={appStoreUrl("navbar")}
          target="_blank"
          rel="noopener noreferrer"
          className="hidden md:flex items-center gap-2 px-4 py-2 rounded-full border border-white/20 text-sm font-medium text-white hover:bg-white/5 transition-colors"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
            <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
          </svg>
          Get the App
        </a>

        {/* Mobile hamburger */}
        <button
          onClick={() => setMobileOpen(!mobileOpen)}
          className="md:hidden p-2 text-white/60"
          aria-label="Toggle menu"
        >
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
          >
            {mobileOpen ? (
              <path d="M18 6L6 18M6 6l12 12" />
            ) : (
              <path d="M4 6h16M4 12h16M4 18h16" />
            )}
          </svg>
        </button>
      </div>

      {/* Mobile menu */}
      {mobileOpen && (
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="md:hidden bg-black/95 backdrop-blur-xl border-t border-white/5 px-6 py-4 space-y-3"
        >
          {navLinks.map((link) => (
            <a
              key={link.href}
              href={link.href}
              onClick={() => setMobileOpen(false)}
              className="block text-sm text-white/60 hover:text-white py-2"
            >
              {link.label}
            </a>
          ))}
          <a
            href={appStoreUrl("navbar_mobile")}
            target="_blank"
            rel="noopener noreferrer"
            className="block text-sm text-center font-medium text-white py-2.5 mt-2 rounded-full border border-white/20"
          >
            Get the App
          </a>
        </motion.div>
      )}
    </motion.nav>
  );
}
