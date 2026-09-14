#!/usr/bin/env node
'use strict';
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const {initializeApp, applicationDefault, deleteApp} = require('firebase-admin/app');
const {getFirestore, FieldPath} = require('firebase-admin/firestore');
const {reconcileConversation} = require('./reconciliation');
function parsePositive(value, name) {
  const number = Number(value);
  if (!Number.isInteger(number) || number <= 0) throw new Error(`INVALID_${name}`);
  return number;
}
function parseArgs(argv) {
  const options = {apply: false, emulator: false, identifierMode: 'hmac',
    pageSize: 100, messagePageSize: 500, startAfter: null,
    maxConversations: null, conversation: null, allowReportInRepo: false};
  const valued = new Set(['--project', '--confirm-project', '--report',
    '--checkpoint', '--resume-from',
    '--conversation', '--start-after', '--max-conversations', '--page-size',
    '--message-page-size', '--identifier-mode']);
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    if (flag === '--apply') options.apply = true;
    else if (flag === '--emulator') options.emulator = true;
    else if (flag === '--allow-report-in-repo') options.allowReportInRepo = true;
    else if (valued.has(flag)) {
      if (!argv[index + 1]) throw new Error('MISSING_FLAG_VALUE');
      const key = flag.slice(2).replace(/-([a-z])/g, (_, letter) =>
        letter.toUpperCase());
      options[key] = argv[index + 1];
      index += 1;
    } else throw new Error('UNKNOWN_FLAG');
  }
  options.pageSize = parsePositive(options.pageSize, 'PAGE_SIZE');
  options.messagePageSize = parsePositive(options.messagePageSize,
      'MESSAGE_PAGE_SIZE');
  if (options.maxConversations !== null) {
    options.maxConversations = parsePositive(options.maxConversations,
        'MAX_CONVERSATIONS');
  }
  if (!options.project || !options.report || !options.checkpoint) {
    throw new Error('REQUIRED_FLAG_MISSING');
  }
  if (options.resumeFrom && options.startAfter) {
    throw new Error('MULTIPLE_RESUME_SOURCES');
  }
  if (!['hmac', 'plain'].includes(options.identifierMode)) {
    throw new Error('INVALID_IDENTIFIER_MODE');
  }
  if (options.apply && (!options.confirmProject ||
options.confirmProject !== options.project)) {
    throw new Error('APPLY_CONFIRMATION_MISMATCH');
  }
  if (options.emulator !== Boolean(process.env.FIRESTORE_EMULATOR_HOST)) {
    throw new Error('EMULATOR_MODE_MISMATCH');
  }
  return options;
}
function findRepositoryRoot(start) {
  let current = path.resolve(start);
  while (current) {
    if (fs.existsSync(path.join(current, '.git'))) return current;
    const parent = path.dirname(current);
    if (parent === current) return null;
    current = parent;
  }
}
function inside(parent, child) {
  const relative = path.relative(parent, child);
  return relative === '' || (!relative.startsWith('..') && !path.isAbsolute(relative));
}
function validateReportPath(report, options, cwd = process.cwd()) {
  const resolved = path.resolve(report);
  const repository = findRepositoryRoot(cwd);
  if (repository && inside(repository, resolved) && !options.allowReportInRepo) {
    throw new Error('REPORT_PATH_INSIDE_REPOSITORY');
  }
  return resolved;
}
function validateOperationalPath(filename, options, cwd = process.cwd()) {
  return validateReportPath(filename, options, cwd);
}
function validateProjectEnvironment(project, environment = process.env) {
  const configured = [environment.GCLOUD_PROJECT,
    environment.GOOGLE_CLOUD_PROJECT].filter(Boolean);
  if (new Set(configured).size > 1 || configured.some((value) => value !== project)) {
    throw new Error('CONFLICTING_PROJECT_ENVIRONMENT');
  }
}
function identifier(value, options, key = process.env.NATTER_REPORT_HMAC_KEY) {
  if (options.identifierMode === 'plain') return value;
  if (!key) throw new Error('REPORT_HMAC_KEY_REQUIRED');
  return `hmac-sha256:${crypto.createHmac('sha256', key).update(value).digest('hex')}`;
}
function newReport(options) {
  return {schemaVersion: 1, mode: options.apply ? 'apply' : 'dry-run',
    identifierMode: options.identifierMode,
    startedAt: new Date().toISOString(), completedAt: null,
    counts: {scanned: 0, eligible: 0, unchanged: 0, writes: 0,
      skipped: 0, errors: 0}, records: [],
    checkpoint: {lastCompletedConversation: options.startAfter ?
identifier(options.startAfter, options) : null}};
}
function writePrivateJson(filename, value) {
  fs.mkdirSync(path.dirname(filename), {recursive: true});
  const temporary = `${filename}.tmp-${process.pid}`;
  fs.writeFileSync(temporary, `${JSON.stringify(value, null, 2)}\n`,
      {mode: 0o600});
  fs.renameSync(temporary, filename);
}
function writeReport(filename, report) {
  writePrivateJson(filename, report);
}
function writeCheckpoint(filename, conversationId) {
  writePrivateJson(filename, {schemaVersion: 1,
    lastCompletedConversationId: conversationId});
}
function loadCheckpoint(filename) {
  const value = JSON.parse(fs.readFileSync(filename, 'utf8'));
  if (value.schemaVersion !== 1 ||
typeof value.lastCompletedConversationId !== 'string' ||
!value.lastCompletedConversationId) {
    throw new Error('INVALID_CHECKPOINT');
  }
  return value.lastCompletedConversationId;
}
async function resolvedProjectId(app) {
  if (app.options.projectId) return app.options.projectId;
  return app.options.credential.getProjectId();
}
async function runBackfill(db, options, reportPath, checkpointPath) {
  const report = newReport(options);
  let cursor = options.startAfter;
  let remaining = options.maxConversations;
  do {
    let query = db.collection('conversations').orderBy(FieldPath.documentId())
        .limit(remaining === null ? options.pageSize :
Math.min(options.pageSize, remaining));
    if (options.conversation) {
      query = db.collection('conversations').where(FieldPath.documentId(),
          '==', options.conversation).limit(1);
    } else if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    if (page.empty) break;
    for (const snapshot of page.docs) {
      const record = {conversation: identifier(snapshot.id, options)};
      try {
        const result = await reconcileConversation(db, snapshot, options);
        report.counts.scanned += 1;
        if (result.reason) {
          report.counts.skipped += 1;
          record.status = 'skipped';
          record.reason = result.reason;
        } else {
          report.counts.eligible += 1;
          report.counts.writes += result.writes;
          record.status = result.writes ?
(options.apply ? 'updated' : 'would-update') : 'unchanged';
          if (!result.writes) report.counts.unchanged += 1;
          record.writeCount = result.writes;
          record.missingRefCount = result.missing;
        }
      } catch (error) {
        report.counts.errors += 1;
        record.status = 'error';
        record.reason = 'PROCESSING_ERROR';
      }
      report.records.push(record);
      cursor = snapshot.id;
      report.checkpoint.lastCompletedConversation = identifier(cursor, options);
      if (remaining !== null) remaining -= 1;
      writeReport(reportPath, report);
      writeCheckpoint(checkpointPath, cursor);
      if (remaining === 0) break;
    }
    if (options.conversation || remaining === 0 || page.size < options.pageSize) break;
  } while (!options.conversation && remaining !== 0);
  report.completedAt = new Date().toISOString();
  writeReport(reportPath, report);
  return report;
}
async function main(argv = process.argv.slice(2)) {
  const options = parseArgs(argv);
  validateProjectEnvironment(options.project);
  const reportPath = validateReportPath(options.report, options);
  const checkpointPath = validateOperationalPath(options.checkpoint, options);
  if (options.resumeFrom) {
    const resumePath = validateOperationalPath(options.resumeFrom, options);
    options.startAfter = loadCheckpoint(resumePath);
  } else if (!options.startAfter && fs.existsSync(checkpointPath)) {
    options.startAfter = loadCheckpoint(checkpointPath);
  }
  identifier('startup-check', options);
  const app = initializeApp({credential: applicationDefault()});
  try {
    const actualProject = await resolvedProjectId(app);
    if (actualProject !== options.project) throw new Error('PROJECT_MISMATCH');
    return await runBackfill(getFirestore(app), options, reportPath,
        checkpointPath);
  } finally {
    await deleteApp(app);
  }
}
if (require.main === module) {
  main().then((report) => {
    console.log(JSON.stringify({mode: report.mode, counts: report.counts}));
  }).catch((error) => {
    console.error(JSON.stringify({error: error.message}));
    process.exitCode = 1;
  });
}
module.exports = {findRepositoryRoot, identifier, loadCheckpoint, main,
  newReport, parseArgs, resolvedProjectId, runBackfill,
  validateOperationalPath, validateProjectEnvironment, validateReportPath,
  writeCheckpoint, writeReport};
