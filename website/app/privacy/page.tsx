import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "Learn how Lock Screen Studio processes calendar, task, and photo data privately on your iPhone.",
  alternates: {
    canonical: "/privacy",
  },
};

export default function PrivacyPage() {
  return (
    <main className="min-h-screen px-6 py-32 max-w-3xl mx-auto">
      <Link
        href="/"
        className="inline-flex items-center gap-2 text-sm text-white/50 hover:text-white/80 transition-colors mb-8"
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M19 12H5M12 19l-7-7 7-7" />
        </svg>
        Back to Home
      </Link>
      <h1 className="text-4xl font-bold mb-8">Privacy Policy</h1>
      <div className="prose prose-invert prose-sm max-w-none text-white/60 space-y-6">
        <p>Last updated: July 2026</p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Overview
        </h2>
        <p>
          Lock Screen Studio (&quot;the App&quot;) is developed and maintained by ARINITSOFT PC SRL, operating as Arinitsolutions (arinitsolutions.com).
          Your privacy is important to us. This policy explains what data the App accesses,
          how it is used, and your rights regarding that data.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Data Collection &amp; Storage
        </h2>
        <p>
          Your calendar entries, reminders, tasks, photos, wallpaper content, and template names
          are processed on your device and are not transmitted to us.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Reminders Access
        </h2>
        <p>
          If you choose Apple Reminders as a To-Do panel source, the App reads
          selected incomplete reminders via EventKit solely while generating your
          wallpaper. Reminder titles, list names, and due dates stay on your device
          and are never included in analytics. You can revoke access at any time via
          iOS Settings &gt; Privacy &amp; Security &gt; Reminders.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Calendar Access
        </h2>
        <p>
          The App requests access to your Apple Calendar (via EventKit) solely to display
          upcoming events on your Lock Screen wallpaper. Calendar data is read locally,
          used only during wallpaper generation, and is never stored, cached, or transmitted
          outside of your device. You can revoke calendar access at any time via
          iOS Settings &gt; Privacy &amp; Security &gt; Calendars.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Photo Library Access
        </h2>
        <p>
          The App may request access to your Photo Library for two purposes:
          (1) to use a photo as a wallpaper background, and (2) to save generated
          wallpaper images to your Camera Roll. Photos selected as backgrounds are
          processed entirely on-device and are never uploaded or shared. You can
          manage photo access in iOS Settings &gt; Privacy &amp; Security &gt; Photos.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Subscriptions &amp; Payments
        </h2>
        <p>
          In-app purchases and subscriptions are processed entirely by Apple through
          the App Store. We do not have access to your payment information, Apple ID,
          or any financial data. For details on how Apple handles payment data, please
          refer to{" "}
          <a
            href="https://www.apple.com/legal/privacy/"
            className="text-indigo-400"
            target="_blank"
            rel="noopener noreferrer"
          >
            Apple&apos;s Privacy Policy
          </a>
          .
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Analytics &amp; Tracking
        </h2>
        <p>
          Lock Screen Studio does not include third-party analytics or advertising trackers
          and does not transmit product-usage events. We do not track your activity across
          other companies&apos; apps or websites.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Data Sharing
        </h2>
        <p>
          We do not sell your data. Payment data is handled separately by Apple as described
          in the Subscriptions &amp; Payments section.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Children&apos;s Privacy
        </h2>
        <p>
          The App is not directed at children under 13. We do not knowingly collect
          personal information from children.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Changes to This Policy
        </h2>
        <p>
          We may update this privacy policy from time to time. Changes will be posted
          on this page with an updated &quot;Last updated&quot; date. Continued use of the App
          after changes constitutes acceptance of the revised policy.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">Contact</h2>
        <p>
          If you have questions about this privacy policy, please contact us at{" "}
          <a
            href="mailto:contact@arinitsolutions.com"
            className="text-indigo-400"
          >
            contact@arinitsolutions.com
          </a>
          .
        </p>
      </div>
    </main>
  );
}
