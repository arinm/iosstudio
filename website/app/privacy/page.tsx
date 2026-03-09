import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy — Lock Screen Studio",
};

export default function PrivacyPage() {
  return (
    <main className="min-h-screen px-6 py-32 max-w-3xl mx-auto">
      <h1 className="text-4xl font-bold mb-8">Privacy Policy</h1>
      <div className="prose prose-invert prose-sm max-w-none text-white/60 space-y-6">
        <p>Last updated: February 2026</p>
        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Data Collection
        </h2>
        <p>
          Lock Screen Studio processes your calendar events and to-do items
          locally on your device to generate wallpaper images. We do not collect,
          store, or transmit any personal data to external servers.
        </p>
        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Calendar Access
        </h2>
        <p>
          The app requests access to your Apple Calendar solely to display
          upcoming events on your Lock Screen wallpaper. Calendar data never
          leaves your device.
        </p>
        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Analytics
        </h2>
        <p>
          We do not use any third-party analytics or tracking services.
        </p>
        <h2 className="text-xl font-semibold text-white/80 mt-8">Contact</h2>
        <p>
          If you have questions about this privacy policy, please contact us at{" "}
          <a
            href="mailto:privacy@lockscreenstudio.app"
            className="text-indigo-400"
          >
            privacy@lockscreenstudio.app
          </a>
          .
        </p>
      </div>
    </main>
  );
}
