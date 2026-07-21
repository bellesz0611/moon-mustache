function clone(value) {
  return structuredClone(value)
}

function jsonSize(value) {
  return JSON.stringify(value).length
}

function replaceAt(root, path, replacement) {
  if (path.length === 0) return replacement
  const copy = clone(root)
  let cursor = copy
  for (const segment of path.slice(0, -1)) cursor = cursor[segment]
  cursor[path.at(-1)] = replacement
  return copy
}

function removeAt(root, path) {
  const copy = clone(root)
  let cursor = copy
  for (const segment of path.slice(0, -1)) cursor = cursor[segment]
  const key = path.at(-1)
  if (Array.isArray(cursor)) cursor.splice(key, 1)
  else delete cursor[key]
  return copy
}

function childPaths(value, path = []) {
  const paths = []
  if (Array.isArray(value)) {
    for (let index = 0; index < value.length; index += 1) {
      paths.push([...path, index])
      paths.push(...childPaths(value[index], [...path, index]))
    }
  } else if (value && typeof value === 'object') {
    for (const key of Object.keys(value)) {
      paths.push([...path, key])
      paths.push(...childPaths(value[key], [...path, key]))
    }
  }
  return paths.sort((left, right) => right.length - left.length)
}

function minimizeString(initial, tryValue) {
  let current = initial
  let granularity = 2
  while (current.length > 0) {
    const chunkSize = Math.ceil(current.length / granularity)
    let reduced = false
    for (let start = 0; start < current.length; start += chunkSize) {
      const candidate = current.slice(0, start) + current.slice(start + chunkSize)
      if (candidate === current || !tryValue(candidate)) continue
      current = candidate
      granularity = Math.max(2, granularity - 1)
      reduced = true
      break
    }
    if (reduced) continue
    if (granularity >= current.length) break
    granularity = Math.min(current.length, granularity * 2)
  }
  return current
}

export function minimizeFailure(fixture, stillFails, options = {}) {
  const maxEvaluations = options.maxEvaluations ?? 250
  let evaluations = 0
  let current = clone(fixture)

  function accept(candidate) {
    if (evaluations >= maxEvaluations) return false
    evaluations += 1
    if (!stillFails(candidate)) return false
    current = clone(candidate)
    return true
  }

  if (!stillFails(current)) {
    throw new Error('cannot minimize a fixture that does not reproduce the failure')
  }

  const originalSize = jsonSize(current)
  const minimizedTemplate = minimizeString(current.template, (template) =>
    accept({ ...current, template }),
  )
  current.template = minimizedTemplate

  let changed = true
  while (changed && evaluations < maxEvaluations) {
    changed = false
    for (const path of childPaths(current.context)) {
      const candidate = { ...current, context: removeAt(current.context, path) }
      if (!accept(candidate)) continue
      changed = true
      break
    }
  }

  for (const key of Object.keys(current.partials)) {
    const candidatePartials = { ...current.partials }
    delete candidatePartials[key]
    accept({ ...current, partials: candidatePartials })
  }

  for (const key of Object.keys(current.partials)) {
    const minimizedPartial = minimizeString(current.partials[key], (value) => {
      const partials = { ...current.partials, [key]: value }
      return accept({ ...current, partials })
    })
    current.partials[key] = minimizedPartial
  }

  for (const replacement of ['', false, 0, null]) {
    for (const path of childPaths(current.context)) {
      const candidate = {
        ...current,
        context: replaceAt(current.context, path, replacement),
      }
      accept(candidate)
    }
  }

  return {
    fixture: current,
    evaluations,
    max_evaluations: maxEvaluations,
    original_size: originalSize,
    minimized_size: jsonSize(current),
  }
}
