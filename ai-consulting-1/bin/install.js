#!/usr/bin/env node
// Installs the Imogen AI consulting skills bundled in this package for Claude Code, Codex and Cursor.
//   npx imogen-skills@latest                     auto-detect tools
//   npx imogen-skills@latest --tools codex,cursor
//   npx imogen-skills@latest --dir .agents/skills
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');

const TOOLS = ['claude', 'codex', 'cursor'];
const HELP = `Usage: npx imogen-skills@latest [--tools claude,codex,cursor] [--dir <folder>]

  --tools  Install for these tools instead of auto-detecting
  --dir    Install into this one folder only (e.g. .agents/skills for one project)

Re-run to update.`;

function parseArgs(argv) {
  const opts = {};
  for (let i = 0; i < argv.length; i++) {
    const [flag, inline] = argv[i].split('=', 2);
    const value = () => {
      const v = inline !== undefined ? inline : argv[++i];
      if (!v) throw new Error(`${flag} needs a value`);
      return v;
    };
    if (flag === '--tools') opts.tools = value().split(',').map((t) => t.trim().toLowerCase()).filter(Boolean);
    else if (flag === '--dir') opts.dir = value();
    else if (flag === '-h' || flag === '--help') opts.help = true;
    else throw new Error(`Unknown option: ${argv[i]}`);
  }
  return opts;
}

function onPath(cmd) {
  const exts = process.platform === 'win32' ? (process.env.PATHEXT || '.EXE;.CMD;.BAT').split(';') : [''];
  return (process.env.PATH || '').split(path.delimiter).some((dir) =>
    dir && exts.some((ext) => fs.existsSync(path.join(dir, cmd + ext.toLowerCase())) || fs.existsSync(path.join(dir, cmd + ext))),
  );
}

function detectTools(home) {
  return TOOLS.filter((t) => fs.existsSync(path.join(home, `.${t}`)) || onPath(t));
}

// Claude Code reads ~/.claude/skills, Codex reads ~/.agents/skills, and Cursor reads both
// (plus ~/.cursor/skills). Pick the fewest folders that cover the tools in use, so Cursor
// doesn't list every skill twice unless Claude and Codex are both installed.
function targetDirs(tools, home) {
  const dirs = [];
  if (tools.includes('claude')) dirs.push(path.join(home, '.claude', 'skills'));
  if (tools.includes('codex')) dirs.push(path.join(home, '.agents', 'skills'));
  if (tools.includes('cursor') && dirs.length === 0) dirs.push(path.join(home, '.cursor', 'skills'));
  return dirs;
}

function skillDirs(root) {
  return fs
    .readdirSync(root, { withFileTypes: true })
    .filter((e) => e.isDirectory() && fs.existsSync(path.join(root, e.name, 'SKILL.md')))
    .map((e) => e.name);
}

function main() {
  const opts = parseArgs(process.argv.slice(2));
  if (opts.help) return console.log(HELP);

  const home = os.homedir();
  let dests;
  if (opts.dir) {
    dests = [path.resolve(opts.dir)];
  } else {
    let tools = opts.tools || detectTools(home);
    const unknown = tools.filter((t) => !TOOLS.includes(t));
    if (unknown.length) throw new Error(`Unknown tool(s): ${unknown.join(', ')}. Use claude, codex and/or cursor.`);
    if (tools.length === 0) {
      console.log('No Claude Code, Codex or Cursor install found; installing for all three.');
      tools = TOOLS;
    }
    console.log(`Installing for: ${tools.join(', ')}`);
    dests = targetDirs(tools, home);
  }

  const src = path.join(__dirname, '..');
  const skills = skillDirs(src);
  for (const dest of dests) {
    fs.mkdirSync(dest, { recursive: true });
    for (const name of skills) {
      const target = path.join(dest, name);
      fs.rmSync(target, { recursive: true, force: true });
      fs.cpSync(path.join(src, name), target, { recursive: true });
    }
    console.log(`  ${skills.length} skills -> ${dest}`);
  }

  console.log("Done. Start a new session, then describe what you're doing or call ask-imogen");
  console.log('(Claude Code / Cursor: /ask-imogen   Codex: $ask-imogen).');
}

try {
  main();
} catch (err) {
  console.error(`imogen-skills: ${err.message}`);
  process.exit(1);
}
