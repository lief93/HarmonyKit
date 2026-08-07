import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const SELECTOR_NAME = /^[A-Za-z_$][A-Za-z0-9_$]*$/;

function isIdentifierStart(char) {
  return char !== undefined && /[A-Za-z_$]/.test(char);
}

function isIdentifierPart(char) {
  return char !== undefined && /[A-Za-z0-9_$]/.test(char);
}

function skipQuoted(source, start, quote) {
  let index = start + 1;
  while (index < source.length) {
    if (source[index] === '\\') {
      index += 2;
      continue;
    }
    if (source[index] === quote) {
      return index + 1;
    }
    index += 1;
  }
  return source.length;
}

function skipLineComment(source, start) {
  const newline = source.indexOf('\n', start + 2);
  return newline === -1 ? source.length : newline;
}

function skipBlockComment(source, start) {
  const end = source.indexOf('*/', start + 2);
  return end === -1 ? source.length : end + 2;
}

function skipTrivia(source, start) {
  let index = start;
  while (index < source.length) {
    if (/\s/.test(source[index])) {
      index += 1;
    } else if (source.startsWith('//', index)) {
      index = skipLineComment(source, index);
    } else if (source.startsWith('/*', index)) {
      index = skipBlockComment(source, index);
    } else {
      break;
    }
  }
  return index;
}

function readStringLiteral(source, start) {
  const quote = source[start];
  if (quote !== "'" && quote !== '"') {
    return undefined;
  }

  let value = '';
  let index = start + 1;
  while (index < source.length) {
    const char = source[index];
    if (char === '\\') {
      if (index + 1 >= source.length) {
        return undefined;
      }
      value += source[index + 1];
      index += 2;
    } else if (char === quote) {
      return { value, end: index + 1 };
    } else {
      value += char;
      index += 1;
    }
  }
  return undefined;
}

function findClosingParenthesis(source, openIndex) {
  let depth = 0;
  let index = openIndex;
  while (index < source.length) {
    const char = source[index];
    if (char === "'" || char === '"' || char === '`') {
      index = skipQuoted(source, index, char);
    } else if (source.startsWith('//', index)) {
      index = skipLineComment(source, index);
    } else if (source.startsWith('/*', index)) {
      index = skipBlockComment(source, index);
    } else {
      if (char === '(') {
        depth += 1;
      } else if (char === ')') {
        depth -= 1;
        if (depth === 0) {
          return index;
        }
      }
      index += 1;
    }
  }
  return undefined;
}

function lineAt(source, offset) {
  let line = 1;
  for (let index = 0; index < offset; index += 1) {
    if (source[index] === '\n') {
      line += 1;
    }
  }
  return line;
}

function collectTestCalls(source) {
  const calls = [];
  let index = 0;
  while (index < source.length) {
    const char = source[index];
    if (char === "'" || char === '"' || char === '`') {
      index = skipQuoted(source, index, char);
      continue;
    }
    if (source.startsWith('//', index)) {
      index = skipLineComment(source, index);
      continue;
    }
    if (source.startsWith('/*', index)) {
      index = skipBlockComment(source, index);
      continue;
    }
    if (!isIdentifierStart(char)) {
      index += 1;
      continue;
    }

    const identifierStart = index;
    index += 1;
    while (isIdentifierPart(source[index])) {
      index += 1;
    }
    const kind = source.slice(identifierStart, index);
    if (kind !== 'it' && kind !== 'describe') {
      continue;
    }

    const openIndex = skipTrivia(source, index);
    if (source[openIndex] !== '(') {
      continue;
    }
    const nameStart = skipTrivia(source, openIndex + 1);
    const name = readStringLiteral(source, nameStart);
    const closeIndex = findClosingParenthesis(source, openIndex);
    if (name === undefined || closeIndex === undefined) {
      continue;
    }
    calls.push({
      kind,
      name: name.value,
      startLine: lineAt(source, identifierStart),
      endLine: lineAt(source, closeIndex)
    });
  }
  return calls;
}

function chooseSmallest(calls) {
  return [...calls].sort((left, right) => {
    const leftSpan = left.endLine - left.startLine;
    const rightSpan = right.endLine - right.startLine;
    return leftSpan - rightSpan || right.startLine - left.startLine;
  })[0];
}

export function resolveSelector(source, line, defaultSuite = 'MainHarUiTest') {
  const lineCount = source.split('\n').length;
  if (!Number.isInteger(line) || line < 1 || line > lineCount) {
    throw new Error(`line must be between 1 and ${lineCount}`);
  }
  if (!SELECTOR_NAME.test(defaultSuite)) {
    throw new Error(`invalid default test class '${defaultSuite}'`);
  }

  const containing = collectTestCalls(source).filter((call) =>
    line >= call.startLine && line <= call.endLine
  );
  const method = chooseSmallest(containing.filter((call) => call.kind === 'it'));
  if (method !== undefined) {
    if (!SELECTOR_NAME.test(method.name)) {
      throw new Error(`test method '${method.name}' cannot be used as a class selector`);
    }
    return `${defaultSuite}#${method.name}`;
  }

  const suite = chooseSmallest(containing.filter((call) => call.kind === 'describe'));
  if (suite !== undefined) {
    if (!SELECTOR_NAME.test(suite.name)) {
      throw new Error(`test class '${suite.name}' cannot be used as a class selector`);
    }
    return suite.name;
  }

  throw new Error('the cursor is not inside a describe() test class or it() test method');
}

function main() {
  const [, , filePath, lineValue, defaultSuite = 'MainHarUiTest'] = process.argv;
  if (filePath === undefined || lineValue === undefined) {
    throw new Error('usage: resolve-uitest-selector.mjs <file> <line> [default-suite]');
  }
  const line = Number(lineValue);
  const source = readFileSync(filePath, 'utf8');
  process.stdout.write(`${resolveSelector(source, line, defaultSuite)}\n`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    main();
  } catch (error) {
    process.stderr.write(`uitest-current: ${error.message}\n`);
    process.exitCode = 2;
  }
}
