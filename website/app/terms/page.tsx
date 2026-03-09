import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Terms of Service — Lock Screen Studio",
};

export default function TermsPage() {
  return (
    <main className="min-h-screen px-6 py-32 max-w-3xl mx-auto">
      <h1 className="text-4xl font-bold mb-8">Terms of Service</h1>
      <div className="prose prose-invert prose-sm max-w-none text-white/60 space-y-6">
        <p>Last updated: February 2026</p>
        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Usage
        </h2>
        <p>
          Lock Screen Studio is provided as-is. You may use the app to generate
          wallpaper images for personal use on your iOS devices.
        </p>
        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Subscriptions
        </h2>
        <p>
          Pro features are available through an in-app purchase. Subscriptions
          are managed through your Apple ID and can be canceled at any time via
          iOS Settings.
        </p>
        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Limitations
        </h2>
        <p>
          We are not responsible for any issues arising from wallpaper
          generation, including but not limited to calendar data accuracy or
          device compatibility.
        </p>
        <h2 className="text-xl font-semibold text-white/80 mt-8">Contact</h2>
        <p>
          For questions about these terms, contact us at{" "}
          <a
            href="mailto:support@lockscreenstudio.app"
            className="text-indigo-400"
          >
            support@lockscreenstudio.app
          </a>
          .
        </p>
      </div>
    </main>
  );
}
