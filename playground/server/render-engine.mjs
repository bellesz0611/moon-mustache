import { execFile } from 'node:child_process'
import { promisify } from 'node:util'
import path from 'node:path'
import os from 'node:os'
import { fileURLToPath } from 'node:url'

const execFileAsync = promisify(execFile)
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..')
const bridgeOutput = path.join(
  repoRoot,
  '_build',
  'js',
  'debug',
  'build',
  'playground_bridge',
  'playground_bridge.js',
)

function resolveMoonBinary() {
  if (process.env.MOON_BIN) {
    return process.env.MOON_BIN
  }
  if (process.platform === 'win32') {
    return path.join(os.homedir(), '.moon', 'bin', 'moon.exe')
  }
  return path.join(os.homedir(), '.moon', 'bin', 'moon')
}

async function ensureBridgeBuilt() {
  const moon = resolveMoonBinary()
  await execFileAsync(moon, ['build', '--target', 'js'], {
    cwd: repoRoot,
    windowsHide: true,
  })
}

function encodeText(value) {
  return Buffer.from(value, 'utf8').toString('base64')
}

export async function renderTemplate({
  template,
  contextJson,
  partialsJson,
  strictMissing,
}) {
  await ensureBridgeBuilt()
  const args = [
    bridgeOutput,
    '--template-base64',
    encodeText(template),
    '--context-base64',
    encodeText(contextJson),
    '--partials-base64',
    encodeText(partialsJson),
  ]
  if (strictMissing) {
    args.push('--strict-missing')
  }
  const { stdout, stderr } = await execFileAsync(process.execPath, args, {
    cwd: repoRoot,
    windowsHide: true,
  })
  if (stderr && stderr.trim()) {
    throw new Error(stderr.trim())
  }
  return JSON.parse(stdout.trim())
}
