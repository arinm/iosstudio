"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";
import Image from "next/image";

interface ScreenshotPhone {
  src: string;
  alt: string;
}

const row1: ScreenshotPhone[] = [
  { src: "/screenshots/gallery-templates.png", alt: "Template gallery" },
  { src: "/screenshots/editor-today-dashboard.png", alt: "Editor - Today Dashboard" },
  { src: "/screenshots/preview-photo-wallpaper.png", alt: "Preview with photo wallpaper" },
  { src: "/screenshots/theme-picker-colors.png", alt: "Theme color customization" },
  { src: "/screenshots/export-screen.png", alt: "Export screen" },
  { src: "/screenshots/gallery-templates.png", alt: "Template gallery" },
  { src: "/screenshots/editor-today-dashboard.png", alt: "Editor - Today Dashboard" },
  { src: "/screenshots/preview-photo-wallpaper.png", alt: "Preview with photo wallpaper" },
];

const row2: ScreenshotPhone[] = [
  { src: "/screenshots/shortcuts-automation.png", alt: "Shortcuts automation" },
  { src: "/screenshots/theme-picker-photo.png", alt: "Theme picker with photo" },
  { src: "/screenshots/add-panel-sheet.png", alt: "Add panel options" },
  { src: "/screenshots/editor-morning-briefing.png", alt: "Editor - Morning Briefing" },
  { src: "/screenshots/shortcuts-automation.png", alt: "Shortcuts automation" },
  { src: "/screenshots/theme-picker-photo.png", alt: "Theme picker with photo" },
  { src: "/screenshots/add-panel-sheet.png", alt: "Add panel options" },
  { src: "/screenshots/editor-morning-briefing.png", alt: "Editor - Morning Briefing" },
];

function PhoneFrame({ src, alt }: ScreenshotPhone) {
  return (
    <div className="relative w-[160px] h-[340px] flex-shrink-0 rounded-[24px] border-[2px] border-white/10 overflow-hidden bg-black shadow-2xl">
      <Image
        src={src}
        alt={alt}
        fill
        className="object-cover"
        sizes="160px"
      />
    </div>
  );
}

export default function PhoneShowcase() {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-50px" });

  return (
    <section className="pt-4 pb-8 relative" ref={ref}>
      {/* Row 1 — scrolls left */}
      <motion.div
        initial={{ opacity: 0, y: 60 }}
        animate={isInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.8, ease: "easeOut" }}
        className="fade-edges mb-8 overflow-hidden"
      >
        <div className="animate-scroll-left flex gap-6 w-max">
          {[...row1, ...row1].map((phone, i) => (
            <PhoneFrame key={i} {...phone} />
          ))}
        </div>
      </motion.div>

      {/* Row 2 — scrolls right */}
      <motion.div
        initial={{ opacity: 0, y: 60 }}
        animate={isInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.8, delay: 0.2, ease: "easeOut" }}
        className="fade-edges overflow-hidden"
      >
        <div className="animate-scroll-right flex gap-6 w-max">
          {[...row2, ...row2].map((phone, i) => (
            <PhoneFrame key={i} {...phone} />
          ))}
        </div>
      </motion.div>
    </section>
  );
}
