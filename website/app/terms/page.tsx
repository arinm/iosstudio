import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Terms of Service — Lock Screen Studio",
};

export default function TermsPage() {
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
      <h1 className="text-4xl font-bold mb-8">Terms of Service</h1>
      <div className="prose prose-invert prose-sm max-w-none text-white/60 space-y-6">
        <p>Last updated: March 2026</p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Acceptance of Terms
        </h2>
        <p>
          By downloading, installing, or using Lock Screen Studio (&quot;the App&quot;),
          you agree to be bound by these Terms of Service. If you do not agree to
          these terms, do not use the App.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Description of Service
        </h2>
        <p>
          Lock Screen Studio is an iOS application that generates custom wallpaper
          images for your device&apos;s Lock Screen. The App allows you to combine
          calendar events, tasks, priorities, and other data into visual layouts
          that can be saved as wallpaper images.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Free &amp; Pro Features
        </h2>
        <p>
          The App offers both free and premium (&quot;Pro&quot;) features. Free users can access
          a limited set of templates and a daily export limit. Pro features, including
          all templates, unlimited exports, premium themes, and full Shortcuts automation,
          require an active subscription.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Subscriptions &amp; Billing
        </h2>
        <ul className="list-disc pl-6 space-y-2">
          <li>
            Lock Screen Studio Pro is available as a monthly or yearly auto-renewing
            subscription.
          </li>
          <li>
            Payment is charged to your Apple ID account at confirmation of purchase.
          </li>
          <li>
            Subscriptions automatically renew unless auto-renew is turned off at least
            24 hours before the end of the current billing period.
          </li>
          <li>
            Your account will be charged for renewal within 24 hours prior to the end
            of the current period, at the same price.
          </li>
          <li>
            You can manage and cancel your subscriptions by going to your device&apos;s
            Settings &gt; Apple ID &gt; Subscriptions.
          </li>
          <li>
            Any unused portion of a free trial period, if offered, will be forfeited
            when you purchase a subscription.
          </li>
          <li>
            Prices are in USD and may vary by region. Price changes will not affect
            active subscription periods.
          </li>
        </ul>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Refunds
        </h2>
        <p>
          All purchases are processed by Apple. Refund requests must be submitted
          through Apple&apos;s standard refund process at{" "}
          <a
            href="https://reportaproblem.apple.com"
            className="text-indigo-400"
            target="_blank"
            rel="noopener noreferrer"
          >
            reportaproblem.apple.com
          </a>
          . We do not process refunds directly.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          User Responsibilities
        </h2>
        <p>
          You are responsible for ensuring that your use of the App complies with
          applicable laws. You agree not to reverse-engineer, decompile, or
          disassemble the App, or use it for any unlawful purpose.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Intellectual Property
        </h2>
        <p>
          The App, including its design, code, templates, and visual assets, is the
          intellectual property of Lock Screen Studio. Wallpaper images you generate
          using your own data are yours to use freely.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Disclaimer of Warranties
        </h2>
        <p>
          The App is provided &quot;as is&quot; and &quot;as available&quot; without warranties of any
          kind, either express or implied. We do not guarantee that the App will be
          error-free, uninterrupted, or compatible with all devices.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Limitation of Liability
        </h2>
        <p>
          To the maximum extent permitted by law, Lock Screen Studio shall not be
          liable for any indirect, incidental, special, or consequential damages
          arising from your use of the App, including but not limited to issues with
          calendar data accuracy, wallpaper rendering, or device compatibility.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Changes to Terms
        </h2>
        <p>
          We reserve the right to modify these terms at any time. Changes will be
          posted on this page with an updated date. Continued use of the App after
          changes constitutes acceptance of the revised terms.
        </p>

        <h2 className="text-xl font-semibold text-white/80 mt-8">
          Governing Law
        </h2>
        <p>
          These terms are governed by the laws of Romania, without regard to conflict
          of law principles.
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
