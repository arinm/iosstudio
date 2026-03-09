import Image from "next/image";

interface PhoneMockupProps {
  gradient?: string;
  label?: string;
  size?: "sm" | "md" | "lg";
  className?: string;
  children?: React.ReactNode;
  screenshot?: string;
}

const sizes = {
  sm: { w: "w-[160px]", h: "h-[340px]", radius: "rounded-[24px]" },
  md: { w: "w-[240px]", h: "h-[500px]", radius: "rounded-[36px]" },
  lg: { w: "w-[280px]", h: "h-[580px]", radius: "rounded-[42px]" },
};

const gradients = [
  "from-indigo-900 via-indigo-800 to-slate-900",
  "from-slate-900 via-purple-900 to-slate-900",
  "from-slate-900 via-slate-800 to-slate-900",
  "from-indigo-950 via-blue-900 to-slate-900",
  "from-emerald-950 via-slate-900 to-slate-900",
  "from-violet-950 via-indigo-900 to-slate-900",
  "from-rose-950 via-slate-900 to-slate-900",
];

export default function PhoneMockup({
  gradient,
  label,
  size = "md",
  className = "",
  children,
  screenshot,
}: PhoneMockupProps) {
  const s = sizes[size];
  const grad = gradient || gradients[Math.floor(Math.random() * gradients.length)];

  return (
    <div className={`relative ${s.w} ${s.h} flex-shrink-0 ${className}`}>
      {/* Phone frame */}
      <div
        className={`relative ${s.w} ${s.h} ${s.radius} border-[2px] border-white/10 overflow-hidden bg-gradient-to-b ${grad} shadow-2xl`}
      >
        {/* Content area */}
        {screenshot ? (
          <Image
            src={screenshot}
            alt={label || "App screenshot"}
            fill
            className="object-cover"
            sizes={size === "sm" ? "160px" : size === "md" ? "240px" : "280px"}
          />
        ) : (
          <div className="absolute inset-0 flex flex-col items-center justify-center p-6">
            {children || (
              <>
                {/* Placeholder wallpaper content */}
                <div className="text-center space-y-4 w-full">
                  {/* Time */}
                  <div className="text-white/30 text-xs font-medium tracking-wide mt-6">
                    {label || "Today"}
                  </div>
                  <div className="text-white/80 text-4xl font-light tracking-tight">
                    {new Date().getHours().toString().padStart(2, "0")}:
                    {new Date().getMinutes().toString().padStart(2, "0")}
                  </div>

                  {/* Panel placeholders */}
                  <div className="space-y-2 mt-4">
                    <div className="h-2 bg-white/10 rounded-full w-3/4 mx-auto" />
                    <div className="h-2 bg-white/10 rounded-full w-1/2 mx-auto" />
                    <div className="h-2 bg-white/8 rounded-full w-2/3 mx-auto" />
                  </div>

                  <div className="space-y-1.5 mt-3">
                    <div className="flex items-center gap-2 mx-auto w-fit">
                      <div className="w-2 h-2 rounded-full bg-indigo-400/60" />
                      <div className="h-1.5 bg-white/10 rounded-full w-24" />
                    </div>
                    <div className="flex items-center gap-2 mx-auto w-fit">
                      <div className="w-2 h-2 rounded-full bg-indigo-400/40" />
                      <div className="h-1.5 bg-white/10 rounded-full w-20" />
                    </div>
                    <div className="flex items-center gap-2 mx-auto w-fit">
                      <div className="w-2 h-2 rounded-full bg-indigo-400/30" />
                      <div className="h-1.5 bg-white/10 rounded-full w-16" />
                    </div>
                  </div>
                </div>
              </>
            )}
          </div>
        )}

        {/* Home indicator */}
        <div className="absolute bottom-2 left-1/2 -translate-x-1/2">
          <div className="w-24 h-1 bg-white/20 rounded-full" />
        </div>
      </div>
    </div>
  );
}
