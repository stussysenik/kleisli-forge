import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editorContainer", "preview", "vueTab", "svelteTab", "copyBtn"]
  static values = {
    activeFramework: { type: String, default: "vue" }
  }

  connect() {
    this.editors = {}
    this.sources = this.#loadSources()
    this.debounceTimer = null
    this.#initEditor()
  }

  disconnect() {
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    Object.values(this.editors).forEach(view => view.destroy())
  }

  switchTab(event) {
    const framework = event.currentTarget.dataset.framework
    if (framework === this.activeFrameworkValue) return

    this.activeFrameworkValue = framework
    this.#updateTabStyles()
    this.#showEditor(framework)
    this.#updatePreview()
  }

  async copy() {
    const source = this.#currentSource()
    try {
      await navigator.clipboard.writeText(source)
      const btn = this.copyBtnTarget
      const original = btn.textContent
      btn.textContent = "Copied!"
      setTimeout(() => { btn.textContent = original }, 1500)
    } catch {
      const ta = document.createElement("textarea")
      ta.value = source
      document.body.appendChild(ta)
      ta.select()
      document.execCommand("copy")
      document.body.removeChild(ta)
    }
  }

  // --- Private ---

  #loadSources() {
    const sources = {}
    const dataEl = document.getElementById("component-sources")
    if (dataEl) {
      try {
        const data = JSON.parse(dataEl.textContent)
        for (const [fw, info] of Object.entries(data)) {
          sources[fw] = {
            code: info.source_code || "",
            previewHtml: info.preview_html || "",
            filename: info.filename || `component.${fw === "vue" ? "vue" : "svelte"}`,
            qualityScore: info.quality_score || null
          }
        }
      } catch (e) {
        console.error("Failed to parse component sources:", e)
      }
    }
    return sources
  }

  async #initEditor() {
    try {
      const [
        { basicSetup },
        { EditorState },
        { EditorView },
        { html },
        { javascript },
        { oneDark }
      ] = await Promise.all([
        import("codemirror"),
        import("@codemirror/state"),
        import("@codemirror/view"),
        import("@codemirror/lang-html"),
        import("@codemirror/lang-javascript"),
        import("@codemirror/theme-one-dark")
      ])

      // Create editor for each framework
      for (const [fw, info] of Object.entries(this.sources)) {
        const container = document.createElement("div")
        container.classList.add("h-full")
        container.dataset.framework = fw
        container.style.display = fw === this.activeFrameworkValue ? "block" : "none"
        this.editorContainerTarget.appendChild(container)

        const updateListener = EditorView.updateListener.of(update => {
          if (update.docChanged) {
            this.sources[fw].code = update.state.doc.toString()
            this.#debouncedPreview()
          }
        })

        const state = EditorState.create({
          doc: info.code,
          extensions: [
            basicSetup,
            fw === "vue" ? html() : javascript(),
            oneDark,
            updateListener,
            EditorView.lineWrapping
          ]
        })

        this.editors[fw] = new EditorView({ state, parent: container })
      }

      this.#updateTabStyles()
      this.#updatePreview()
    } catch (e) {
      console.error("CodeMirror load failed:", e)
      this.#initFallbackEditor()
    }
  }

  #initFallbackEditor() {
    // Fallback: use a plain textarea when CodeMirror can't load
    for (const [fw, info] of Object.entries(this.sources)) {
      const container = document.createElement("div")
      container.classList.add("h-full")
      container.dataset.framework = fw
      container.style.display = fw === this.activeFrameworkValue ? "block" : "none"

      const textarea = document.createElement("textarea")
      textarea.className = "w-full h-full bg-gray-900 text-gray-100 font-mono text-xs p-4 resize-none border-0 outline-none"
      textarea.value = info.code
      textarea.addEventListener("input", () => {
        this.sources[fw].code = textarea.value
        this.#debouncedPreview()
      })

      container.appendChild(textarea)
      this.editorContainerTarget.appendChild(container)
    }
    this.#updateTabStyles()
    this.#updatePreview()
  }

  #showEditor(framework) {
    this.editorContainerTarget.querySelectorAll("[data-framework]").forEach(el => {
      el.style.display = el.dataset.framework === framework ? "block" : "none"
    })
  }

  #updateTabStyles() {
    const active = this.activeFrameworkValue
    ;[this.vueTabTarget, this.svelteTabTarget].forEach(tab => {
      const fw = tab.dataset.framework
      if (fw === active) {
        tab.classList.add("border-b-2", "border-indigo-500", "text-indigo-600")
        tab.classList.remove("text-gray-500")
      } else {
        tab.classList.remove("border-b-2", "border-indigo-500", "text-indigo-600")
        tab.classList.add("text-gray-500")
      }
    })
  }

  #debouncedPreview() {
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.#updatePreview(), 400)
  }

  #updatePreview() {
    const fw = this.activeFrameworkValue
    const info = this.sources[fw]
    if (!info) return

    const iframe = this.previewTarget
    if (fw === "vue") {
      iframe.srcdoc = this.#buildVuePreview(info.code)
    } else {
      if (info.previewHtml) {
        iframe.srcdoc = info.previewHtml
      } else {
        iframe.srcdoc = this.#buildStaticPreview(info.code, "Svelte")
      }
    }
  }

  #buildVuePreview(sfcSource) {
    const templateMatch = sfcSource.match(/<template[^>]*>([\s\S]*?)<\/template>/)
    const scriptMatch = sfcSource.match(/<script[^>]*>([\s\S]*?)<\/script>/)
    const styleMatch = sfcSource.match(/<style[^>]*>([\s\S]*?)<\/style>/)

    const template = templateMatch ? templateMatch[1].trim() : "<div>No template</div>"
    const style = styleMatch ? styleMatch[1] : ""

    let scriptBody = ""
    if (scriptMatch) {
      scriptBody = scriptMatch[1]
        .replace(/export\s+default\s*/, "")
        .replace(/import\s+.*?['"].*?['"]\s*;?\n?/g, "")
        .trim()
    }

    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <script src="https://unpkg.com/vue@3/dist/vue.global.prod.js"><\/script>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: system-ui, -apple-system, sans-serif; padding: 16px; background: #fff; }
    ${style}
  </style>
</head>
<body>
  <div id="app">${template}</div>
  <script>
    try {
      const options = ${scriptBody || "{}"};
      Vue.createApp(options).mount("#app");
    } catch(e) {
      document.getElementById("app").innerHTML = '<pre style="color:red;font-size:12px">' + e.message + '<\\/pre>';
    }
  <\/script>
</body>
</html>`
  }

  #buildStaticPreview(source, framework) {
    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: system-ui, sans-serif; padding: 24px; background: #f9fafb; color: #6b7280; text-align: center; }
    .badge { display: inline-block; background: #fef3c7; color: #92400e; padding: 4px 12px; border-radius: 9999px; font-size: 12px; font-weight: 500; margin-bottom: 16px; }
    pre { text-align: left; background: #1f2937; color: #e5e7eb; padding: 16px; border-radius: 8px; font-size: 11px; overflow: auto; max-height: 400px; }
  </style>
</head>
<body>
  <span class="badge">Static Preview — ${framework}</span>
  <p style="font-size:13px;margin-bottom:16px">${framework} components require compilation for live preview.</p>
  <pre>${this.#escapeHtml(source)}</pre>
</body>
</html>`
  }

  #currentSource() {
    const info = this.sources[this.activeFrameworkValue]
    return info ? info.code : ""
  }

  #escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
