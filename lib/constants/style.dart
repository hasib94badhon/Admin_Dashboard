import 'package:flutter/material.dart';

// ── Sidebar ──────────────────────────────────────────────────────────────────
const Color sidebarBg         = Color(0xFF0F172A); // slate-900
const Color sidebarHoverBg    = Color(0xFF1E293B); // slate-800
const Color sidebarBorderColor= Color(0xFF1E293B); // slate-800

// ── Surface ───────────────────────────────────────────────────────────────────
const Color background        = Color(0xFFF8FAFC); // slate-50
const Color surface           = Color(0xFFFFFFFF);
const Color borderColor       = Color(0xFFE2E8F0); // slate-200

// ── Text ──────────────────────────────────────────────────────────────────────
const Color textPrimary       = Color(0xFF1E293B); // slate-800
const Color textSecondary     = Color(0xFF64748B); // slate-500
const Color textMuted         = Color(0xFF94A3B8); // slate-400
const Color textOnDark        = Color(0xFFE2E8F0); // slate-200  (on sidebar)
const Color textOnDarkMuted   = Color(0xFF64748B); // slate-500  (inactive items)

// ── Accent ───────────────────────────────────────────────────────────────────
const Color accentColor       = Color(0xFF6366F1); // indigo-500
const Color accentLight       = Color(0xFFEEF2FF); // indigo-50

// ── Status ────────────────────────────────────────────────────────────────────
const Color successColor      = Color(0xFF22C55E);
const Color warningColor      = Color(0xFFF59E0B);
const Color errorColor        = Color(0xFFEF4444);

// ── Legacy aliases (keep backward-compat across existing pages) ───────────────
const light     = background;
const lightGrey = textSecondary;
const dark      = textPrimary;
const active    = accentColor;
