interface LockScreenMockupProps {
  gradient?: string;
  size?: "sm" | "md" | "lg";
  className?: string;
  /** Template content to show below the clock */
  panels?: PanelContent[];
  /** Date text shown above the clock */
  dateText?: string;
  /** Time text */
  timeText?: string;
}

interface PanelContent {
  title?: string;
  lines: { text: string; accent?: boolean; dim?: boolean }[];
}

const sizes = {
  sm: {
    w: "w-[160px]",
    h: "h-[340px]",
    radius: "rounded-[24px]",
    clock: "text-[40px]",
    date: "text-[7px]",
    title: "text-[5px]",
    body: "text-[5px]",
    padTop: "pt-8",
    gap: "gap-[3px]",
    panelGap: "gap-[6px]",
    lineH: "leading-[7px]",
    titleSpacing: "tracking-[1.5px]",
  },
  md: {
    w: "w-[240px]",
    h: "h-[500px]",
    radius: "rounded-[36px]",
    clock: "text-[60px]",
    date: "text-[10px]",
    title: "text-[7px]",
    body: "text-[8px]",
    padTop: "pt-12",
    gap: "gap-1",
    panelGap: "gap-2",
    lineH: "leading-[11px]",
    titleSpacing: "tracking-[2px]",
  },
  lg: {
    w: "w-[280px]",
    h: "h-[580px]",
    radius: "rounded-[42px]",
    clock: "text-[72px]",
    date: "text-[12px]",
    title: "text-[8px]",
    body: "text-[9px]",
    padTop: "pt-14",
    gap: "gap-1",
    panelGap: "gap-3",
    lineH: "leading-[13px]",
    titleSpacing: "tracking-[2.5px]",
  },
};

export default function LockScreenMockup({
  gradient = "from-slate-950 via-indigo-950 to-black",
  size = "md",
  className = "",
  panels = [],
  dateText,
  timeText,
}: LockScreenMockupProps) {
  const s = sizes[size];

  const now = new Date();
  const date =
    dateText ||
    now.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" });
  const time =
    timeText ||
    `${now.getHours().toString().padStart(2, "0")}:${now.getMinutes().toString().padStart(2, "0")}`;

  return (
    <div className={`relative ${s.w} ${s.h} flex-shrink-0 ${className}`}>
      <div
        className={`relative ${s.w} ${s.h} ${s.radius} border-[2px] border-white/10 overflow-hidden bg-gradient-to-b ${gradient} shadow-2xl`}
      >
        {/* Lock Screen content */}
        <div className={`absolute inset-0 flex flex-col items-center ${s.padTop} px-4`}>
          {/* Date */}
          <p
            className={`${s.date} font-medium text-white/60 tracking-wide`}
          >
            {date}
          </p>

          {/* Clock */}
          <p
            className={`${s.clock} font-thin text-white tracking-tight leading-none mt-0.5`}
          >
            {time}
          </p>

          {/* Panels */}
          <div className={`w-full mt-auto mb-auto flex flex-col ${s.panelGap} px-1`}>
            {panels.map((panel, i) => (
              <div key={i} className={`flex flex-col ${s.gap}`}>
                {panel.title && (
                  <p
                    className={`${s.title} font-semibold text-white/40 uppercase ${s.titleSpacing}`}
                  >
                    {panel.title}
                  </p>
                )}
                {panel.lines.map((line, j) => (
                  <p
                    key={j}
                    className={`${s.body} ${s.lineH} ${
                      line.accent
                        ? "text-indigo-400 font-medium"
                        : line.dim
                        ? "text-white/30"
                        : "text-white/70"
                    }`}
                  >
                    {line.text}
                  </p>
                ))}
              </div>
            ))}
          </div>

          {/* Bottom icons (flashlight & camera) */}
          <div className="flex justify-between w-full px-2 pb-3 mt-auto">
            <div className="w-8 h-8 rounded-full bg-white/10 backdrop-blur-sm flex items-center justify-center">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="white" fillOpacity={0.6}>
                <path d="M9 21c0 .55.45 1 1 1h4c.55 0 1-.45 1-1v-1H9v1zm3-19C8.14 2 5 5.14 5 9c0 2.38 1.19 4.47 3 5.74V17c0 .55.45 1 1 1h6c.55 0 1-.45 1-1v-2.26c1.81-1.27 3-3.36 3-5.74 0-3.86-3.14-7-7-7z" />
              </svg>
            </div>
            <div className="w-8 h-8 rounded-full bg-white/10 backdrop-blur-sm flex items-center justify-center">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="white" fillOpacity={0.6}>
                <path d="M12 15.2a3.2 3.2 0 100-6.4 3.2 3.2 0 000 6.4z" />
                <path d="M9 2L7.17 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2h-3.17L15 2H9zm3 15c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5z" />
              </svg>
            </div>
          </div>
        </div>

        {/* Home indicator */}
        <div className="absolute bottom-2 left-1/2 -translate-x-1/2">
          <div className="w-20 h-1 bg-white/20 rounded-full" />
        </div>
      </div>
    </div>
  );
}
