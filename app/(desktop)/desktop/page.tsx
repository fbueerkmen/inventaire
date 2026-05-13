import Link from "next/link";

import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export default function DesktopPlaceholderPage() {
  return (
    <main className="mx-auto flex min-h-full max-w-2xl flex-col gap-6 px-6 py-12">
      <p className="text-muted-foreground text-sm">
        Espace desktop (admin) — placeholder. Retour à l’accueil.
      </p>
      <Link
        href="/"
        className={cn(buttonVariants({ variant: "outline" }), "min-h-11 w-fit justify-center")}
      >
        Accueil
      </Link>
    </main>
  );
}
