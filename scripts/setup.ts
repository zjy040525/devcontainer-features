import { link, mkdir, readdir, rm } from 'node:fs/promises'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const featureName = 'claude-config-persist'

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const sourceDirectory = join(projectRoot, 'src', featureName)
const targetDirectory = join(projectRoot, '.devcontainer', featureName)

console.log('Cleaning up old directory...')
await rm(targetDirectory, { force: true, recursive: true })

console.log('Creating target directory...')
await mkdir(targetDirectory, { recursive: true })

console.log('Creating hard links...')
const filenames = (await readdir(sourceDirectory)).filter(filename => !filename.startsWith('.'))
await Promise.all(
  filenames.map(filename => link(
    join(sourceDirectory, filename),
    join(targetDirectory, filename),
  )),
)

console.log('Done! Hard links are ready. You can now \'Reopen in Container\' in VS Code.')
