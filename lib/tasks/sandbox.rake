namespace :sandbox do
  desc "Install Node.js dependencies for the compilation sandbox"
  task setup: :environment do
    scripts_dir = Rails.root.join("lib", "sandbox", "scripts")

    puts "Installing sandbox dependencies..."
    system("cd #{scripts_dir} && npm install") || abort("Failed to install sandbox dependencies")
    puts "Sandbox setup complete!"
  end

  desc "Verify sandbox is working"
  task verify: :environment do
    puts "Testing Vue compiler..."
    vue_source = <<~VUE
      <template>
        <div>{{ message }}</div>
      </template>
      <script setup>
      const message = 'Hello'
      </script>
    VUE

    result = Sandbox::VueCompiler.new.compile(vue_source)
    if result["success"]
      puts "  Vue compilation: OK"
    else
      puts "  Vue compilation: FAILED - #{result['error']}"
    end

    puts "Testing Svelte compiler..."
    svelte_source = <<~SVELTE
      <script>
        let message = 'Hello';
      </script>
      <div>{message}</div>
    SVELTE

    result = Sandbox::SvelteCompiler.new.compile(svelte_source)
    if result["success"]
      puts "  Svelte compilation: OK"
    else
      puts "  Svelte compilation: FAILED - #{result['error']}"
    end
  end
end
