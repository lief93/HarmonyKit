import assert from 'node:assert/strict';
import test from 'node:test';
import { resolveSelector } from '../resolve-uitest-selector.mjs';

function lineOf(source, text) {
  return source.slice(0, source.indexOf(text)).split('\n').length;
}

const specSource = `
import { it } from '@ohos/hypium';

export function registerSpecs(): void {
  // it('commentOnly', 0, () => {});
  it(
    'runsCurrentMethod',
    0,
    async () => {
      const text = "describe('notAClass')";
      const template = \`a value with ) and it('notATest')\`;
      if (text.length > 0) {
        await Promise.resolve(template);
      }
    }
  );

  it('runsSecondMethod', 0, () => {
    /* A comment with a misleading closing parenthesis: ) */
    return;
  });
}
`;

test('resolves the method containing the cursor', () => {
  assert.equal(
    resolveSelector(specSource, lineOf(specSource, 'await Promise.resolve')),
    'MainHarUiTest#runsCurrentMethod'
  );
});

test('resolves a method from its declaration line', () => {
  assert.equal(
    resolveSelector(specSource, lineOf(specSource, "it('runsSecondMethod'")),
    'MainHarUiTest#runsSecondMethod'
  );
});

test('ignores test-like text in comments and strings', () => {
  assert.throws(
    () => resolveSelector(specSource, lineOf(specSource, "it('commentOnly'")),
    /cursor is not inside/
  );
});

test('resolves the describe class containing the cursor', () => {
  const suiteSource = `
describe('MainHarUiTest', () => {
  registerMainPageSpecs();
  registerNavigationSpecs();
});
`;
  assert.equal(
    resolveSelector(suiteSource, lineOf(suiteSource, 'registerNavigationSpecs')),
    'MainHarUiTest'
  );
});

test('prefers a method nested inside a describe class', () => {
  const nestedSource = `
describe('MainHarUiTest', () => {
  it('nestedMethod', 0, async () => {
    await Promise.resolve();
  });
});
`;
  assert.equal(
    resolveSelector(nestedSource, lineOf(nestedSource, 'Promise.resolve')),
    'MainHarUiTest#nestedMethod'
  );
});

test('rejects a cursor outside a test class or method', () => {
  assert.throws(
    () => resolveSelector(specSource, lineOf(specSource, 'registerSpecs')),
    /cursor is not inside/
  );
});

test('rejects a line outside the file', () => {
  assert.throws(() => resolveSelector(specSource, 0), /line must be between/);
});

test('rejects method names unsupported by the strict runner selector', () => {
  const source = "it('name with spaces', 0, () => {});";
  assert.throws(() => resolveSelector(source, 1), /cannot be used as a class selector/);
});
