const { rowsFromItems, todayStr } = require('./index');

const sampleItems = [
  {
    id: 'doc1',
    path: 'sample/doc1',
    data: { foo: 'bar', n: 1 },
    subcollections: { child: [{ id: 'c1', path: 'sample/doc1/child/c1', data: { a: 1 }, subcollections: {} }] },
  },
  {
    id: 'doc2',
    path: 'sample/doc2',
    data: { baz: true },
    subcollections: {},
  },
];

const date = todayStr();
const rows = rowsFromItems(date, 'sample', sampleItems);
console.log(JSON.stringify({ date, count: rows.length, first: rows[0] }, null, 2));
