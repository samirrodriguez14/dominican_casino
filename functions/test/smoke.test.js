const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");

test("functions build outputs lib/index.js", () => {
  assert.ok(fs.existsSync("lib/index.js"));
});

