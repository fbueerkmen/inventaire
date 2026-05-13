import Link from "next/link";

import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export default function MobilePlaceholderPage() {
  return (
    <main className="mx-auto flex min-h-full max-w-md flex-col gap-6 px-4 py-10">
      <p className="text-muted-foreground text-sm">
        Espace mobile (PWA / opérateurs) — placeholder. Retour à l’accueil.
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
