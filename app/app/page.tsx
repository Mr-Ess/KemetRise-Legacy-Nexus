
export default function Home() {
  return (
    <main className="min-h-screen bg-[#08090b] text-white">
      {/* Header */}
      <header className="border-b border-[#292c33] bg-[#101216]">
        <div className="mx-auto flex min-h-20 w-full max-w-7xl items-center justify-between px-6 lg:px-10">
          <div>
            <div className="text-2xl font-bold tracking-wide text-[#d6a84f]">
              KemetRise
            </div>
            <div className="text-xs tracking-[0.25em] text-[#8b909a]">
              LEGACY NEXUS
            </div>
          </div>

          <div className="hidden text-right sm:block">
            <div className="text-sm font-medium text-white">
              Control Tower
            </div>
            <div className="text-xs text-[#8b909a]">
              Digital Legacy & Enterprise OS
            </div>
          </div>
        </div>
      </header>

      {/* Main */}
      <section className="mx-auto w-full max-w-7xl px-6 py-10 lg:px-10">
        {/* Welcome */}
        <div className="mb-10">
          <p className="mb-2 text-sm font-medium uppercase tracking-[0.25em] text-[#d6a84f]">
            KemetRise Operating System
          </p>

          <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">
            Legacy Nexus
          </h1>

          <p className="mt-4 max-w-2xl text-base leading-7 text-[#8b909a]">
            The central control tower for managing digital legacy,
            enterprise operations, knowledge, automation, and future systems.
          </p>
        </div>

        {/* System Status */}
        <div className="mb-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <div className="rounded-2xl border border-[#292c33] bg-[#101216] p-5">
            <div className="mb-3 text-sm text-[#8b909a]">System Status</div>
            <div className="flex items-center gap-2">
              <span className="h-2.5 w-2.5 rounded-full bg-emerald-500" />
              <span className="font-semibold">Operational</span>
            </div>
          </div>

          <div className="rounded-2xl border border-[#292c33] bg-[#101216] p-5">
            <div className="mb-3 text-sm text-[#8b909a]">Active Domains</div>
            <div className="text-2xl font-semibold">08</div>
          </div>

          <div className="rounded-2xl border border-[#292c33] bg-[#101216] p-5">
            <div className="mb-3 text-sm text-[#8b909a]">Automations</div>
            <div className="text-2xl font-semibold">31</div>
          </div>

          <div className="rounded-2xl border border-[#292c33] bg-[#101216] p-5">
            <div className="mb-3 text-sm text-[#8b909a]">Security</div>
            <div className="flex items-center gap-2">
              <span className="h-2.5 w-2.5 rounded-full bg-[#d6a84f]" />
              <span className="font-semibold">Protected</span>
            </div>
          </div>
        </div>

        {/* Core Modules */}
        <div className="mb-5">
          <h2 className="text-xl font-semibold">Core Modules</h2>
          <p className="mt-1 text-sm text-[#8b909a]">
            The primary systems of the Legacy Nexus.
          </p>
        </div>

        <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-3">
          {[
            {
              title: "Digital Character",
              code: "DCOS",
              description:
                "Digital identity, characters, profiles, behavior, and lifecycle management.",
            },
            {
              title: "Digital Vault",
              code: "DVAULT",
              description:
                "Secure storage and organization of critical digital assets and legacy data.",
            },
            {
              title: "Digital Heir Protocol",
              code: "DHP",
              description:
                "Structured inheritance and continuity of digital identity and assets.",
            },
            {
              title: "Dead Man's Hand",
              code: "DMH",
              description:
                "Controlled emergency and continuity mechanisms for critical digital assets.",
            },
            {
              title: "AI Prompt OS",
              code: "APOS",
              description:
                "Centralized prompt engineering, AI instructions, standards, and reusable intelligence.",
            },
            {
              title: "Enterprise OS",
              code: "KEOS",
              description:
                "Business operations, management, automation, finance, and enterprise intelligence.",
            },
          ].map((module) => (
            <div
              key={module.code}
              className="group rounded-2xl border border-[#292c33] bg-[#101216] p-6 transition-all hover:-translate-y-1 hover:border-[#d6a84f] hover:bg-[#17191f]"
            >
              <div className="mb-5 flex items-start justify-between">
                <div className="flex h-11 w-11 items-center justify-center rounded-xl border border-[#d6a84f]/30 bg-[#d6a84f]/10 text-sm font-bold text-[#d6a84f]">
                  {module.code.slice(0, 2)}
                </div>

                <span className="rounded-full border border-[#292c33] px-3 py-1 text-[10px] tracking-[0.2em] text-[#8b909a]">
                  {module.code}
                </span>
              </div>

              <h3 className="text-lg font-semibold">{module.title}</h3>

              <p className="mt-3 text-sm leading-6 text-[#8b909a]">
                {module.description}
              </p>

              <div className="mt-6 text-sm font-medium text-[#d6a84f] transition-colors group-hover:text-[#f0c96b]">
                Open Module →
              </div>
            </div>
          ))}
        </div>

        {/* Footer */}
        <footer className="mt-16 border-t border-[#292c33] pt-6">
          <div className="flex flex-col gap-2 text-xs text-[#8b909a] sm:flex-row sm:items-center sm:justify-between">
            <span>KemetRise — Legacy Nexus</span>
            <span>Control Tower • Foundation Build</span>
          </div>
        </footer>
      </section>
    </main>
  );
}

