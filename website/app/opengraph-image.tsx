import { ImageResponse } from "next/og";

export const alt = "Lock Screen Studio — Lock Screen Dashboard for iPhone";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          background:
            "radial-gradient(circle at 30% 30%, #312e81 0%, #0a0a14 60%)",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          padding: "80px",
          color: "white",
          fontFamily: "system-ui, sans-serif",
        }}
      >
        <div
          style={{
            fontSize: 28,
            opacity: 0.7,
            letterSpacing: 2,
            textTransform: "uppercase",
            marginBottom: 24,
          }}
        >
          Lock Screen Studio
        </div>
        <div
          style={{
            fontSize: 96,
            fontWeight: 800,
            lineHeight: 1.05,
            letterSpacing: -2,
            display: "flex",
            flexDirection: "column",
          }}
        >
          <span>Lock Screen Dashboard</span>
          <span
            style={{
              background:
                "linear-gradient(90deg, #c7d2fe 0%, #818cf8 50%, #6366f1 100%)",
              backgroundClip: "text",
              color: "transparent",
            }}
          >
            for iPhone
          </span>
        </div>
        <div
          style={{
            fontSize: 32,
            opacity: 0.6,
            marginTop: 40,
            maxWidth: 900,
            lineHeight: 1.3,
          }}
        >
          Your agenda, priorities, and to-dos — rendered as a wallpaper, refreshed daily.
        </div>
      </div>
    ),
    size,
  );
}
