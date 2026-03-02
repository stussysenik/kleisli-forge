#!/usr/bin/env node
// Compiles a Svelte component from stdin, outputs JSON result to stdout

const { compile } = require('svelte/compiler');

let input = '';

process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => { input += chunk; });
process.stdin.on('end', () => {
  try {
    const result = compile(input, {
      filename: 'Component.svelte',
      generate: 'dom',
      css: 'injected',
      dev: false
    });

    console.log(JSON.stringify({
      success: true,
      output: result.js.code,
      css: result.css ? result.css.code : '',
      warnings: result.warnings.map(w => ({
        message: w.message,
        code: w.code
      })),
      stats: {
        vars: result.vars ? result.vars.length : 0
      }
    }));
  } catch (e) {
    console.log(JSON.stringify({
      success: false,
      error: e.message,
      position: e.pos,
      frame: e.frame
    }));
  }
});
