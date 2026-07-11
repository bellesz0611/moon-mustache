import { copyFile, mkdir } from 'node:fs/promises'
import { existsSync } from 'node:fs'
import { homedir } from 'node:os'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { spawnSync } from 'node:child_process'

const scriptDir = dirname(fileURLToPath(import.meta.url))
const playgroundDir = resolve(scriptDir, '..')
const repositoryDir = resolve(playgroundDir, '..')

function moonCandidates() {
  const executable = process.platform === 'win32' ? 'moon.exe' : 'moon'
  return [
    process.env.MOON_BIN,
    resolve(homedir(), 'moon-toolchain', 'bin', executable),
    resolve(homedir(), '.moon', 'bin', executable),
    executable,
  ].filter(Boolean)
}

function runMoon() {
  const args = ['build', '--target', 'js', '--release', 'browser_bridge']
  for (const candidate of moonCandidates()) {
    if (candidate.includes('/') || candidate.includes('\\')) {
      if (!existsSync(candidate)) continue
    }
    const result = spawnSync(candidate, args, {
      cwd: repositoryDir,
      encoding: 'utf8',
      stdio: 'pipe',
    })
    if (!result.error && result.status === 0) return
    if (result.error?.code === 'ENOENT') continue
    process.stderr.write(result.stdout || '')
    process.stderr.write(result.stderr || '')
    throw new Error(`MoonBit browser engine build failed with ${candidate}`)
  }
  throw new Error('MoonBit executable was not found. Install MoonBit or set MOON_BIN.')
}

runMoon()

const source = resolve(
  repositoryDir,
  '_build',
  'js',
  'release',
  'build',
  'browser_bridge',
  'browser_bridge.js',
)
const destination = resolve(playgroundDir, 'src', 'generated', 'moon_mustache.js')
await mkdir(dirname(destination), { recursive: true })
await copyFile(source, destination)
console.log(`MoonBit browser engine: ${destination}`)
