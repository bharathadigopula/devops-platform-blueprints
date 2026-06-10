/*
==============================================================================
HTTP MODULE IMPORTS
==============================================================================
*/

import http from "node:http";

/*
==============================================================================
SERVER CONFIGURATION
==============================================================================
*/

const port = Number.parseInt(process.env.PORT || "8080", 10);
const startedAt = new Date().toISOString();

/*
==============================================================================
ROUTE DEFINITIONS
==============================================================================
*/

const routes = new Map([
  ["/", () => ({
    message: "DevOps platform blueprint service",
    service: process.env.SERVICE_NAME || "aws-ecs-fargate-github-oidc",
    version: process.env.APP_VERSION || "local"
  })],
  ["/health", () => ({
    ok: true,
    startedAt
  })]
]);

/*
==============================================================================
HTTP SERVER
==============================================================================
*/

const server = http.createServer((request, response) => {
  const url = new URL(request.url || "/", `http://${request.headers.host || "localhost"}`);
  const handler = routes.get(url.pathname);

  if (!handler) {
    response.writeHead(404, { "content-type": "application/json" });
    response.end(JSON.stringify({ error: "not_found" }));
    return;
  }

  response.writeHead(200, { "content-type": "application/json" });
  response.end(JSON.stringify(handler()));
});

/*
==============================================================================
SERVER STARTUP
==============================================================================
*/

server.listen(port, "0.0.0.0", () => {
  process.stdout.write(`service listening on ${port}\n`);
});

/*
==============================================================================
SERVER SHUTDOWN
==============================================================================
*/

const shutdown = () => {
  server.close(() => {
    process.exit(0);
  });
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
