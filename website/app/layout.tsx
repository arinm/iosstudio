import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const BASE_URL = "https://www.lockscreenstudio.com";
const APP_STORE_URL =
  "https://apps.apple.com/app/lock-screen-studio/id6761021115";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: "Lock Screen Studio — Lock Screen Dashboard for iPhone",
    template: "%s — Lock Screen Studio",
  },
  description:
    "Transform your iPhone Lock Screen into a personal dashboard with agenda, priorities, to-dos, countdowns, and more. Apple Shortcuts saves a fresh wallpaper to Photos every morning, ready to apply.",
  keywords: [
    "lock screen",
    "lock screen dashboard",
    "wallpaper",
    "iphone",
    "calendar",
    "agenda",
    "dashboard",
    "ios",
    "shortcuts",
    "automation",
  ],
  metadataBase: new URL(BASE_URL),
  alternates: {
    canonical: "/",
  },
  openGraph: {
    title: "Lock Screen Studio — Lock Screen Dashboard for iPhone",
    description:
      "Transform your iPhone Lock Screen into a personal dashboard with agenda, priorities, to-dos, and more.",
    url: BASE_URL,
    siteName: "Lock Screen Studio",
    type: "website",
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: "Lock Screen Studio",
    description:
      "Your schedule, priorities, and to-dos — right on your Lock Screen.",
  },
  robots: {
    index: true,
    follow: true,
  },
  itunes: {
    appId: "6761021115",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              "@context": "https://schema.org",
              "@type": "SoftwareApplication",
              name: "Lock Screen Studio",
              url: BASE_URL,
              downloadUrl: APP_STORE_URL,
              operatingSystem: "iOS",
              applicationCategory: "ProductivityApplication",
              offers: {
                "@type": "Offer",
                price: "0",
                priceCurrency: "USD",
              },
              description:
                "Transform your iPhone Lock Screen into a personal dashboard.",
            }),
          }}
        />
      </head>
      <body className={`${inter.variable} antialiased`}>{children}</body>
    </html>
  );
}
