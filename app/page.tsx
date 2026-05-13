import Link from "next/link";

import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-full max-w-lg flex-1 flex-col justify-center gap-8 px-6 py-16">
      <div className="space-y-2">
        <h1 className="text-2xl font-semibold tracking-tight">
          Inventaire associatif
        </h1>
        <p className="text-muted-foreground text-sm leading-relaxed">
          Socle Next.js — zones mobile (PWA) et desktop (admin) seront branchées
          aux jalons suivants. Aucune fonctionnalité métier sur cette page.
        </p>
      </div>
      <div className="flex flex-col gap-3 sm:flex-row">
        <Link
          href="/mobile"
          className={cn(buttonVariants({ variant: "default" }), "min-h-11 min-w-[11rem] justify-center")}
        >
          Zone mobile
        </Link>
        <Link
          href="/desktop"
          className={cn(
            buttonVariants({ variant: "secondary" }),
            "min-h-11 min-w-[11rem] justify-center"
          )}
        >
          Zone desktop
        </Link>
      </div>
    </main>
  );
}
