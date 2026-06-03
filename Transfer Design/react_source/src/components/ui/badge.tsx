import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "../../lib/utils"

const badgeVariants = cva(
  "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-brand-cyan focus:ring-offset-2",
  {
    variants: {
      variant: {
        default:
          "border-transparent bg-[var(--brand-primary)] text-white shadow hover:bg-[var(--brand-hover)]",
        secondary:
          "border-transparent bg-bg-chip text-text-secondary hover:bg-bg-alt",
        destructive:
          "border-transparent bg-red-500 text-white shadow hover:bg-red-500/80",
        outline: "text-text-primary border-border-subtle",
        technical: "border-[var(--brand-glow)] bg-[var(--brand-light)] text-[var(--brand-technical)] dark:text-[var(--brand-cyan)] dark:border-[rgba(56,189,248,0.35)] dark:bg-[rgba(56,189,248,0.08)]",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  )
}

export { Badge, badgeVariants }
