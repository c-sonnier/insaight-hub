# insAIght Hub – Full Style Guide

## 1. Brand Foundations

**Product Name:** insAIght Hub  
**Rails Model Name:** `InsightItem`  
**Repo Name:** `insAIghtHub`  

**Tagline:**  
> Because understanding beats output.

**Mission (Brand Version):**  
insAIght Hub turns scattered AI output into shared understanding — structured, searchable, and easy to act on.

---

## 2. Logo System

### 2.1 Logo Variants
- **Primary lockup:** Prism “A” + “insAIght Hub”.
- **Icon mark:** Prism “A” only.
- **Monochrome version:** Single-color navy or off‑white.

### 2.2 Usage Rules
- Maintain clear space equal to prism tip height.
- Minimum size:
  - 32px height (icon)
  - 48px height (lockup)
- Backgrounds: light off‑whites or deep navy.
- **Don’ts:** distort, recolor rays, add shadows, rotate.

---

## 3. Color System

### 3.1 Core Brand Palette
| Token | Hex | Usage |
|-------|------|--------|
| `primary` | #33B8ED | Actions, highlights |
| `primary-deep` | #10325B | Shell, sections |
| `primary-deep/hover` | #183C67 | Hover states |

### 3.2 Spectrum Colors (Tagging + Data Viz)
| Name | Hex |
|------|------|
| spectrum-red | #EB413D |
| spectrum-orange | #F9AB4B |
| spectrum-yellow | #FCC64E |
| spectrum-lime | #A1D555 |
| spectrum-cyan | #41BCDB |
| spectrum-indigo | #6772D1 |

### 3.3 Neutral Palette
- Ink: #020617  
- Body: #0f172a  
- Muted: #64748b  
- Borders: #e5e7eb / #cbd5f5  
- Surfaces: #f9fafb / #ffffff  

### 3.4 Semantic Colors
- Info: #0EA5E9  
- Success: #16A34A  
- Warning: #FACC15  
- Error: #EF4444  

---

## 4. DaisyUI Theme Configuration

```js
// tailwind.config.cjs
module.exports = {
  content: [
    "./app/views/**/*.html.erb",
    "./app/javascript/**/*.{js,ts,jsx,tsx}",
    "./app/helpers/**/*.rb",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
        mono: ["JetBrains Mono", "ui-monospace", "SFMono-Regular", "monospace"],
      },
      borderRadius: {
        xl: "0.9rem",
        "2xl": "1.25rem",
      },
    },
  },
  plugins: [require("daisyui")],
  daisyui: {
    themes: [
      {
        insaight: {
          primary: "#33B8ED",
          "primary-content": "#020617",

          secondary: "#6772D1",
          "secondary-content": "#F9FAFB",

          accent: "#F9AB4B",
          "accent-content": "#1F2937",

          neutral: "#0F172A",
          "neutral-content": "#E5E7EB",

          "base-100": "#F9FAFB",
          "base-200": "#E5E7EB",
          "base-300": "#CBD5F5",

          info: "#0EA5E9",
          success: "#16A34A",
          warning: "#FACC15",
          error: "#EF4444",
        },
      },
      "dark",
    ],
  },
};
```

---

## 5. Typography

### 5.1 Fonts
- **Primary:** Inter  
- **Monospace:** JetBrains Mono

### 5.2 Hierarchy
- H1: `text-3xl md:text-4xl font-semibold`
- H2: `text-2xl font-semibold`
- H3: `text-xl font-semibold`
- Body: `text-base leading-relaxed`
- Muted: `text-slate-500`

---

## 6. Layout, Spacing & Shapes

### 6.1 Spacing Scale
Use Tailwind:
- XS: 0.5rem
- S: 0.75rem
- M: 1rem
- L: 1.5rem
- XL: 2rem
- 2XL: 3rem

### 6.2 Corners & Shadows
- Cards: `rounded-xl` or `rounded-2xl`
- Buttons: `rounded-full`
- Shadows: `shadow-md hover:shadow-lg transition`

### 6.3 Core Layout Patterns
- Sidebar + content layout  
- Insight detail:
  - Title + metadata
  - Main artifact block
  - Right rail: history, versions, related

---

## 7. Components

### 7.1 Buttons
Primary:
```html
<button class="btn btn-primary rounded-full px-5">New Insight</button>
```

Secondary:
```html
<button class="btn btn-outline border-slate-300 text-slate-800 rounded-full">View history</button>
```

Ghost:
```html
<button class="btn btn-ghost text-slate-600">More filters</button>
```

### 7.2 Insight Card
```html
<article class="card bg-base-100 shadow-sm hover:shadow-md rounded-2xl border border-base-200 transition">
  <div class="card-body gap-2">
    <div class="flex items-center gap-2">
      <span class="badge badge-sm border-0 bg-primary/10 text-primary font-medium">
        Strategy • GPT-4.1
      </span>
    </div>
    <h2 class="card-title text-lg">How to refine our Q1 onboarding funnel</h2>
    <p class="text-sm text-slate-600 line-clamp-2">
      Synthesized from 12 AI sessions and 4 feedback threads...
    </p>
    <div class="flex justify-between items-center pt-2 text-xs text-slate-500">
      <span>Last updated 2 hours ago</span>
      <span class="flex gap-1 items-center">
        <span class="w-2 h-2 rounded-full bg-success"></span>
        High confidence
      </span>
    </div>
  </div>
</article>
```

### 7.3 Rainbow Tags
```html
<span class="badge border-0 bg-[#EB413D]/10 text-[#EB413D]">Risk</span>
<span class="badge border-0 bg-[#F9AB4B]/10 text-[#F9AB4B]">Opportunity</span>
<span class="badge border-0 bg-[#A1D555]/10 text-[#A1D555]">Customer</span>
<span class="badge border-0 bg-[#41BCDB]/10 text-[#41BCDB]">Process</span>
<span class="badge border-0 bg-[#6772D1]/10 text-[#6772D1]">Experiment</span>
```

---

## 8. Iconography

- Use Heroicons or Lucide
- 1.5–2px stroke
- Minimal, functional

---

## 9. Motion Principles

- Use `transition-all duration-150`
- No bouncy animations
- Use subtle opacity + scale for modals

---

## 10. Voice & Copy Guidelines

**Tone:** clear, analytical, non-hype.

**Empty State Example:**
> **No Insight Items yet**  
> Connect a source or paste an AI conversation to create your first insight.  
> Button: “Create an Insight Item”

**Status Terms:** Draft, In Review, Final, Deprecated.  
**Confidence:** Low / Medium / High.

---

End of Style Guide.
