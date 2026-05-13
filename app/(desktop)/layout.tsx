export default function DesktopGroupLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <div className="bg-background text-foreground min-h-full">
      {children}
    </div>
  );
}
