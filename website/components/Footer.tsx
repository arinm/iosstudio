const footerLinks = {
  Product: [
    { label: "Features", href: "#features" },
    { label: "Templates", href: "#features" },
    { label: "How it works", href: "#how-it-works" },
    { label: "FAQ", href: "#faq" },
  ],
  Legal: [
    { label: "Privacy Policy", href: "/privacy" },
    { label: "Terms of Service", href: "/terms" },
  ],
};

export default function Footer() {
  return (
    <footer className="border-t border-white/5 py-16 px-6">
      <div className="max-w-6xl mx-auto">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-12">
          {/* Brand */}
          <div className="md:col-span-2">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-indigo-700 flex items-center justify-center">
                <svg
                  width="18"
                  height="18"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="white"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <rect x="3" y="3" width="18" height="18" rx="2" />
                  <path d="M3 9h18" />
                  <path d="M9 3v18" />
                </svg>
              </div>
              <span className="font-semibold text-sm text-white tracking-tight">
                Lock Screen Studio
              </span>
            </div>
            <p className="mt-4 text-sm text-white/30 max-w-xs leading-relaxed">
              Your schedule, priorities, and to-dos — right on your Lock Screen.
              Updated daily, automatically.
            </p>
          </div>

          {/* Links */}
          {Object.entries(footerLinks).map(([title, links]) => (
            <div key={title}>
              <h4 className="text-sm font-semibold text-white/50 uppercase tracking-wider">
                {title}
              </h4>
              <ul className="mt-4 space-y-3">
                {links.map((link) => (
                  <li key={link.label}>
                    <a
                      href={link.href}
                      className="text-sm text-white/30 hover:text-white/60 transition-colors"
                    >
                      {link.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Bottom */}
        <div className="mt-16 pt-8 border-t border-white/5 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-xs text-white/20">
            &copy; {new Date().getFullYear()} Lock Screen Studio by{" "}
            <a href="https://arinitsolutions.com" className="text-white/40 hover:text-white/60 transition-colors" target="_blank" rel="noopener noreferrer">Arinitsolutions</a>. All rights reserved.
          </p>
          <a
            href="#download"
            className="text-xs text-indigo-400/60 hover:text-indigo-400 transition-colors"
          >
            Download on the App Store
          </a>
        </div>
      </div>
    </footer>
  );
}
