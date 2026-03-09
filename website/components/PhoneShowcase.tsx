"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";
import LockScreenMockup from "./LockScreenMockup";

const row1: React.ComponentProps<typeof LockScreenMockup>[] = [
  {
    gradient: "from-indigo-950 via-indigo-900 to-slate-950",
    dateText: "Monday, February 23",
    timeText: "09:41",
    panels: [
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
    ],
  },
  {
    gradient: "from-slate-950 via-slate-900 to-slate-950",
    dateText: "Monday, February 23",
    timeText: "09:41",
    panels: [
      {
        lines: [
          { text: "09:00  Team Standup", accent: true },
          { text: "10:30  Design Review" },
          { text: "14:00  Sprint Planning" },
        ],
      },
    ],
  },
  {
    gradient: "from-purple-950 via-indigo-950 to-slate-950",
    dateText: "Monday, February 23",
    timeText: "09:41",
    panels: [
      {
        title: "Focus",
        lines: [
          { text: "1. Ship v1.0", accent: true },
          { text: "2. Review pull requests" },
          { text: "3. Gym at 6pm" },
        ],
      },
    ],
  },
  {
    gradient: "from-blue-950 via-slate-950 to-slate-950",
    dateText: "Monday, February 23",
    timeText: "09:41",
    panels: [
      {
        title: "Agenda",
        lines: [
          { text: "09:00  Team Standup", accent: true },
          { text: "10:30  Design Review" },
          { text: "12:00  Lunch with Alex" },
        ],
      },
      {
        title: "To-Do",
        lines: [
          { text: "\u2611 Reply to emails", dim: true },
          { text: "\u2610 Prepare presentation" },
          { text: "\u2610 Book flight tickets" },
        ],
      },
    ],
  },
  {
    gradient: "from-slate-950 via-gray-950 to-black",
    dateText: "Monday, February 23",
    timeText: "09:41",
    panels: [
      {
        title: "Focus",
        lines: [
          { text: "1. Finish project proposal", accent: true },
          { text: "2. Call dentist" },
          { text: "3. Read 30 pages" },
        ],
      },
      {
        title: "Countdown",
        lines: [
          { text: "42", accent: true },
          { text: "days until Vacation", dim: true },
        ],
      },
    ],
  },
  {
    gradient: "from-emerald-950 via-slate-950 to-slate-950",
    dateText: "Monday, February 23",
    timeText: "09:41",
    panels: [
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
          { text: "Remember to pick up the cake" },
          { text: "and call mom by 5pm" },
        ],
      },
    ],
  },
];

const row2: React.ComponentProps<typeof LockScreenMockup>[] = [
  {
    gradient: "from-sky-950 via-slate-950 to-slate-950",
    dateText: "Monday, February 23",
    timeText: "08:30",
    panels: [
      {
        title: "Agenda",
        lines: [
          { text: "08:00  Math 101", accent: true },
          { text: "10:00  Physics Lab" },
          { text: "13:00  Study Group" },
        ],
      },
      {
        title: "To-Do",
        lines: [
          { text: "\u2610 Submit essay" },
          { text: "\u2610 Read chapter 5" },
        ],
      },
    ],
  },
  {
    gradient: "from-green-950 via-slate-950 to-slate-950",
    dateText: "Monday, February 23",
    timeText: "06:15",
    panels: [
      {
        title: "Today",
        lines: [
          { text: "07:00  Morning Run", accent: true },
          { text: "08:30  Yoga" },
          { text: "18:00  Gym Session" },
        ],
      },
      {
        title: "Focus",
        lines: [
          { text: "1. 10k steps", accent: true },
          { text: "2. Drink 3L water" },
          { text: "3. Sleep by 10pm" },
        ],
      },
    ],
  },
  {
    gradient: "from-rose-950 via-slate-950 to-slate-950",
    dateText: "Monday, February 23",
    timeText: "09:41",
    panels: [
      {
        title: "Meetings",
        lines: [
          { text: "09:00  Kickoff Call", accent: true },
          { text: "11:00  Client Review" },
          { text: "15:00  1:1 with Manager" },
        ],
      },
    ],
  },
  {
    gradient: "from-violet-950 via-indigo-950 to-slate-950",
    dateText: "Monday, February 23",
    timeText: "09:41",
    panels: [
      {
        title: "Agenda",
        lines: [
          { text: "09:00  Team Standup", accent: true },
          { text: "10:30  Design Review" },
          { text: "14:00  Sprint Planning" },
        ],
      },
      {
        title: "Top 3",
        lines: [
          { text: "1. Ship v1.0", accent: true },
          { text: "2. Review PRs" },
          { text: "3. Gym at 6pm" },
        ],
      },
      {
        title: "To-Do",
        lines: [
          { text: "\u2611 Reply to emails", dim: true },
          { text: "\u2610 Prepare deck" },
        ],
      },
    ],
  },
  {
    gradient: "from-amber-950 via-slate-950 to-slate-950",
    dateText: "Monday, February 23",
    timeText: "07:00",
    panels: [
      {
        title: "Agenda",
        lines: [
          { text: "08:00  Morning Meeting", accent: true },
          { text: "10:00  Workshop" },
        ],
      },
      {
        title: "Note",
        lines: [
          { text: "Don't forget to bring laptop charger" },
        ],
      },
    ],
  },
  {
    gradient: "from-cyan-950 via-slate-950 to-slate-950",
    dateText: "Monday, February 23",
    timeText: "09:41",
    panels: [
      {
        title: "Quote",
        lines: [
          { text: '"The best way to predict the future"' },
          { text: '"is to create it."', dim: true },
          { text: "— Peter Drucker", dim: true },
        ],
      },
    ],
  },
];

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
          {[...row1, ...row1].map((props, i) => (
            <LockScreenMockup key={i} size="sm" {...props} />
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
          {[...row2, ...row2].map((props, i) => (
            <LockScreenMockup key={i} size="sm" {...props} />
          ))}
        </div>
      </motion.div>
    </section>
  );
}
