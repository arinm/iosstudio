import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy — Lock Screen Studio",
};

export default function PrivacyPage() {
  return (
    <main className="min-h-screen px-6 py-32 max-w-3xl mx-auto">
      <a
        href="/"
        className="inline-flex items-center gap-2 text-sm text-white/50 hover:text-white/80 transition-colors mb-8"
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M19 12H5M12 19l-7-7 7-7" />
        </svg>
        Back to Home
      </a>
      <h1 className="text-4xl font-bold mb-8">Privacy Policy</h1>
      <div className="prose prose-invert prose-sm max-w-none text-white/60 space-y-6">
        <p>Last updated: March 2026</p>

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
          Lock Screen Studio does <strong>not</strong> collect, store, or transmit any personal
          data to external servers. All data processing happens entirely on your device.
          We do not operate any backend servers, databases, or cloud infrastructure
          that receives your data.
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
          We do not use any third-party analytics, advertising, or tracking services.
          We do not collect crash reports, usage statistics, or device identifiers.
          The App does not contain any SDKs that track user behavior.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Data Sharing
        </h2>
        <p>
          We do not share, sell, or transfer any user data to third parties.
          Since no data is collected, there is no data to share.
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
