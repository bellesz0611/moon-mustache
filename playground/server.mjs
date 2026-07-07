import http from 'node:http'
import { renderTemplate } from './server/render-engine.mjs'

const port = Number(process.env.PLAYGROUND_API_PORT || 4177)

function sendJson(response, status, payload) {
  response.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  })
  response.end(JSON.stringify(payload))
}

function readJsonBody(request) {
  return new Promise((resolve, reject) => {
    let raw = ''
    request.on('data', chunk => {
      raw += chunk
    })
    request.on('end', () => {
      try {
        resolve(raw ? JSON.parse(raw) : {})
      } catch (error) {
        reject(error)
      }
    })
    request.on('error', reject)
  })
}

const server = http.createServer(async (request, response) => {
  const url = new URL(request.url || '/', `http://${request.headers.host}`)

  if (request.method === 'OPTIONS') {
    sendJson(response, 200, { ok: true })
    return
  }

  if (request.method === 'GET' && url.pathname === '/api/health') {
    sendJson(response, 200, { ok: true })
    return
  }

  if (request.method === 'POST' && url.pathname === '/api/render') {
    try {
      const body = await readJsonBody(request)
      const template = typeof body.template === 'string' ? body.template : ''
      const contextJson =
        typeof body.contextJson === 'string' ? body.contextJson : '{}'
      const partialsJson =
        typeof body.partialsJson === 'string' ? body.partialsJson : '{}'
      const strictMissing = Boolean(body.strictMissing)
      const result = await renderTemplate({
        template,
        contextJson,
        partialsJson,
        strictMissing,
      })
      sendJson(response, 200, result)
    } catch (error) {
      sendJson(response, 500, {
        output: '',
        errors: [error instanceof Error ? error.message : String(error)],
        missing_variables: [],
      })
    }
    return
  }

  sendJson(response, 404, {
    output: '',
    errors: ['not found'],
    missing_variables: [],
  })
})

server.listen(port, '127.0.0.1', () => {
  console.log(`Moon Mustache playground API listening on http://127.0.0.1:${port}`)
})
