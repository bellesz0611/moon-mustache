export function buildEvidenceLayers(verification) {
  const backendResults = verification.backend_conformance.results
  const backendPassed = backendResults.filter(item => item.status === 'passed').length
  return [
    {
      id: 'fault-injection',
      label: 'Controlled faults',
      value: `${verification.fault_injection.killed} / ${verification.fault_injection.total} killed`,
      note: `${verification.fault_injection.survived} survived, ${verification.fault_injection.invalid} invalid; JSON + per-mutant JUnit.`,
    },
    {
      id: 'differential',
      label: 'Differential parity',
      value: `${verification.differential_policy.cases} generated cases`,
      note: `${verification.differential_policy.seeds.length} fixed seeds against ${verification.differential_policy.reference}; replay JSON + JUnit.`,
    },
    {
      id: 'backends',
      label: 'Backend golden corpus',
      value: `${backendPassed} / ${backendResults.length} local targets`,
      note: 'Byte-identical output and diagnostics; CI additionally requires the native target.',
    },
    {
      id: 'cli',
      label: 'CLI black-box contracts',
      value: `${verification.cli_integration.passed} / ${verification.cli_integration.total} passing`,
      note: 'Real subprocess exit codes, file IO, strict failures, traversal, and duplicate paths.',
    },
  ]
}

export function buildMutationRows(faultInjection) {
  return faultInjection.mutations.map(mutation => ({
    name: mutation.name,
    risk: mutation.risk,
    detector: mutation.test_filter.replaceAll('*', ''),
    status: mutation.status,
  }))
}
