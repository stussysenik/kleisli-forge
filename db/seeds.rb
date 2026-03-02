# Design Tokens
puts "Seeding design tokens..."

tokens = [
  # Colors
  { name: "color-primary", category: "color", value: "#3b82f6", css_variable: "--color-primary" },
  { name: "color-primary-dark", category: "color", value: "#2563eb", css_variable: "--color-primary-dark" },
  { name: "color-secondary", category: "color", value: "#64748b", css_variable: "--color-secondary" },
  { name: "color-success", category: "color", value: "#22c55e", css_variable: "--color-success" },
  { name: "color-danger", category: "color", value: "#ef4444", css_variable: "--color-danger" },
  { name: "color-warning", category: "color", value: "#f59e0b", css_variable: "--color-warning" },
  { name: "color-info", category: "color", value: "#06b6d4", css_variable: "--color-info" },
  { name: "color-text", category: "color", value: "#1e293b", css_variable: "--color-text" },
  { name: "color-text-muted", category: "color", value: "#64748b", css_variable: "--color-text-muted" },
  { name: "color-bg", category: "color", value: "#ffffff", css_variable: "--color-bg" },
  { name: "color-bg-secondary", category: "color", value: "#f8fafc", css_variable: "--color-bg-secondary" },
  { name: "color-border", category: "color", value: "#e2e8f0", css_variable: "--color-border" },

  # Spacing
  { name: "spacing-xs", category: "spacing", value: "0.25rem", css_variable: "--spacing-xs" },
  { name: "spacing-sm", category: "spacing", value: "0.5rem", css_variable: "--spacing-sm" },
  { name: "spacing-md", category: "spacing", value: "1rem", css_variable: "--spacing-md" },
  { name: "spacing-lg", category: "spacing", value: "1.5rem", css_variable: "--spacing-lg" },
  { name: "spacing-xl", category: "spacing", value: "2rem", css_variable: "--spacing-xl" },
  { name: "spacing-2xl", category: "spacing", value: "3rem", css_variable: "--spacing-2xl" },

  # Typography
  { name: "font-family", category: "typography", value: "system-ui, -apple-system, sans-serif", css_variable: "--font-family" },
  { name: "font-mono", category: "typography", value: "'SF Mono', 'Fira Code', monospace", css_variable: "--font-mono" },
  { name: "font-size-xs", category: "typography", value: "0.75rem", css_variable: "--font-size-xs" },
  { name: "font-size-sm", category: "typography", value: "0.875rem", css_variable: "--font-size-sm" },
  { name: "font-size-base", category: "typography", value: "1rem", css_variable: "--font-size-base" },
  { name: "font-size-lg", category: "typography", value: "1.125rem", css_variable: "--font-size-lg" },
  { name: "font-size-xl", category: "typography", value: "1.25rem", css_variable: "--font-size-xl" },

  # Shadows
  { name: "shadow-sm", category: "shadow", value: "0 1px 2px rgba(0,0,0,0.05)", css_variable: "--shadow-sm" },
  { name: "shadow-md", category: "shadow", value: "0 4px 6px rgba(0,0,0,0.1)", css_variable: "--shadow-md" },
  { name: "shadow-lg", category: "shadow", value: "0 10px 15px rgba(0,0,0,0.1)", css_variable: "--shadow-lg" },

  # Borders
  { name: "border-radius-sm", category: "border", value: "0.25rem", css_variable: "--border-radius-sm" },
  { name: "border-radius", category: "border", value: "0.375rem", css_variable: "--border-radius" },
  { name: "border-radius-lg", category: "border", value: "0.5rem", css_variable: "--border-radius-lg" },
  { name: "border-radius-full", category: "border", value: "9999px", css_variable: "--border-radius-full" }
]

tokens.each do |token_attrs|
  DesignToken.find_or_create_by!(name: token_attrs[:name]) do |t|
    t.assign_attributes(token_attrs)
  end
end

puts "  Created #{DesignToken.count} design tokens"

# Demo user
if Rails.env.development?
  puts "Creating demo user..."
  user = User.find_or_create_by!(email: "demo@nim-engine.dev") do |u|
    u.password = "password123"
    u.name = "Demo User"
  end
  puts "  Demo user: #{user.email} / password123"
  puts "  API key: #{user.api_key}"
end

puts "Seeding complete!"
