#!/usr/bin/env node
// Compiles a Vue 3 SFC from stdin, outputs JSON result to stdout

const { parse, compileScript, compileTemplate, compileStyle } = require('@vue/compiler-sfc');

let input = '';

process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => { input += chunk; });
process.stdin.on('end', () => {
  try {
    const { descriptor, errors } = parse(input, { filename: 'Component.vue' });

    if (errors.length > 0) {
      console.log(JSON.stringify({
        success: false,
        errors: errors.map(e => e.message)
      }));
      process.exit(0);
    }

    const result = { success: true, sections: {} };

    // Compile template
    if (descriptor.template) {
      const templateResult = compileTemplate({
        source: descriptor.template.content,
        filename: 'Component.vue',
        id: 'component',
        compilerOptions: { mode: 'module' }
      });

      result.sections.template = {
        code: templateResult.code,
        errors: templateResult.errors.map(e => typeof e === 'string' ? e : e.message)
      };
    }

    // Compile script
    if (descriptor.script || descriptor.scriptSetup) {
      try {
        const scriptResult = compileScript(descriptor, {
          id: 'component',
          inlineTemplate: true
        });
        result.sections.script = {
          code: scriptResult.content,
          bindings: scriptResult.bindings
        };
      } catch (e) {
        result.sections.script = { code: '', error: e.message };
      }
    }

    // Compile styles
    if (descriptor.styles.length > 0) {
      result.sections.styles = descriptor.styles.map((style, i) => {
        const styleResult = compileStyle({
          source: style.content,
          filename: 'Component.vue',
          id: `data-v-component`,
          scoped: style.scoped
        });
        return {
          code: styleResult.code,
          errors: styleResult.errors.map(e => e.message)
        };
      });
    }

    result.output = generateOutput(result);
    console.log(JSON.stringify(result));
  } catch (e) {
    console.log(JSON.stringify({
      success: false,
      error: e.message,
      stack: e.stack
    }));
  }
});

function generateOutput(result) {
  let output = '';
  if (result.sections.script) {
    output += result.sections.script.code + '\n';
  }
  if (result.sections.styles) {
    output += result.sections.styles.map(s => s.code).join('\n');
  }
  return output;
}
