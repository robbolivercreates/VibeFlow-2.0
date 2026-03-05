---
name: Landing Page Rebrand
description: Systematic 8-step workflow to rebrand a SaaS landing page — colors, logo, copy, trusted brands, pricing, reviews, and final verification.
---

# Landing Page Rebrand Skill

## Overview

This skill provides a systematic workflow to fully rebrand any SaaS landing page template. It covers six core customization areas and follows a strict order to avoid rework.

## Required Information (Collect First)

Before starting, collect these **6 elements** from the user:

| # | Element | What to Ask |
|---|---------|-------------|
| 1 | **Colors** | Primary accent hex, secondary hex, background hex, muted text hex |
| 2 | **Logo** | Logo image file(s) — navbar (40×40), footer (32×32), favicon (32×32) |
| 3 | **Copy** | Brand name, headline, sub-headline, feature descriptions, CTA labels |
| 4 | **Trusted Brands** | Company names or logos for social proof section |
| 5 | **Pricing** | Plan names, prices, billing periods, feature lists |
| 6 | **Reviews** | Customer quotes, names, roles, avatar images |

> [!IMPORTANT]
> Never assume or invent any of these elements. If the user hasn't provided something, ask.

## Workflow

### Step 1 — Collect All Information
- Ask for all 6 elements in a single organized message
- Provide the Asset Dimensions table (see below)
- Confirm all collected information before proceeding

### Step 2 — Colors (Most Critical)
- [ ] Map old colors → new colors (create a replacement table)
- [ ] Update `tailwind.config.ts` or CSS variables with new palette
- [ ] Update `globals.css` / `index.css` for body bg, selection, scrollbar
- [ ] **Audit each component individually** for missed colors:
  - [ ] Hero — button gradients, glow effects, orb backgrounds
  - [ ] Features — card accents, icon backgrounds
  - [ ] Pricing — highlighted plan accents, badges
  - [ ] Testimonials — star colors, accent elements
  - [ ] Social Proof — badge colors, accent text
  - [ ] Navbar — CTA button, active states
  - [ ] Footer — link hover states, accent elements
  - [ ] All UI sub-components
- [ ] Verify no hardcoded values remain:
  - [ ] `grep_search` for old hex codes (both cases)
  - [ ] Search for `rgba()` variants
  - [ ] Check gradient definitions: `from-[#`, `via-[#`, `to-[#`

### Step 3 — Logo
- [ ] Save uploaded logo files to `/public/`
- [ ] Update Navbar — swap icon/image, update brand name
- [ ] Update Footer — same
- [ ] Update `<title>` and add `<link rel="icon">` for favicon

### Step 4 — Copy
- [ ] Hero — headline, sub-headline, badge, CTAs
- [ ] Navbar — nav links, CTA label
- [ ] Features — section title, card titles, descriptions
- [ ] Pricing — section headline, sub-text
- [ ] Footer — tagline, copyright, column titles/links
- [ ] HTML head — `<title>`, meta description

### Step 5 — Trusted Brands
- [ ] Update social proof component with new brand names or `<img>` logos
- [ ] If using images, save to `/public/brands/`

### Step 6 — Pricing
- [ ] Replace pricing plans array with new data

### Step 7 — Reviews
- [ ] Replace testimonials array with new data
- [ ] If avatars provided, save to `/public/avatars/`

### Step 8 — Final Verification
- [ ] Run `npm run dev` and visually verify
- [ ] Comprehensive color grep audit (hex, rgba, gradient variants)
- [ ] Check for remaining old brand name references
- [ ] Visual verification:
  - [ ] All gradients render with new colors
  - [ ] Button hover glows use new color
  - [ ] Background orbs/effects show new accent
  - [ ] Icon colors updated
  - [ ] Text selection highlight uses new color
- [ ] Confirm all links and CTAs work
- [ ] Test responsive design on mobile viewport

## Asset Dimensions

| Asset | Dimensions | Format | Notes |
|-------|-----------|--------|-------|
| Navbar logo | 40 × 40 px | SVG or PNG (transparent) | Square |
| Footer logo | 32 × 32 px | SVG or PNG (transparent) | Smaller version |
| Favicon | 32 × 32 px | ICO or PNG | Browser tab |
| Brand logos | height 48–64 px | SVG preferred | For marquee/grid |
| Avatars | 100 × 100 px | PNG or JPG | Displayed as circle |

## Gradient Handling Guide

### Types of Gradients

1. **Button gradients:** `bg-gradient-to-r from-[#old] via-[#mid] to-[#old]` → replace ALL stops
2. **Text gradients:** `bg-clip-text text-transparent bg-gradient-to-r from-[#] to-[#]`
3. **SVG gradients:** `<stop stopColor='#old' />` inside `<linearGradient>`
4. **Shadow glows:** `hover:shadow-[0_0_40px_rgba(R,G,B,0.5)]` → convert new hex to rgba

### Strategy
- For 3-stop gradients: `from-[primary] via-[lighter] to-[primary]`
- Derive mid-point by lightening primary ~15%

## Error Handling

- `npm install` fails → check Node ≥ 18
- Colors still wrong → grep for old hex (both cases), rgba variants, gradient stops
- Gradients invisible → ensure `bg-clip-text text-transparent` present
- Logo not loading → verify paths relative to `/public/`, referenced from root (`/logo.svg`)
- TypeScript errors → usually type hints, won't block dev mode

## Interaction Style

- **Systematic** — work phases 1–8 in order
- **Specific** — state exact dimensions and formats when asking for assets
- **Efficient** — ask for all items within a phase in a single message
- **Confirmatory** — summarize all collected info before implementing
- **Never assume** — don't invent brand names, pricing, or testimonials
