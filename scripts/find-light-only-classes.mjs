/**
 * Reports class attributes that paint a light tint (bg-<colour>-50/100/200)
 * or a light-only text colour with no matching `dark:` partner in the same
 * attribute. Those are the ones that stay bright when the page is dark.
 *
 * Usage: node scripts/find-light-only-classes.mjs <path...>
 */
import { globSync, readFileSync } from 'node:fs';

const COLOURS =
    'amber|green|blue|yellow|red|emerald|orange|sky|indigo|purple|pink|teal|cyan|violet|rose|lime';

const patterns = [
    {
        kind: 'tint-bg',
        re: new RegExp(`\\bbg-(?:${COLOURS})-(?:50|100|200)\\b`),
    },
    {
        kind: 'light-text',
        re: new RegExp(`\\btext-(?:${COLOURS})-(?:7|8|9)00\\b`),
    },
    {
        kind: 'light-border',
        re: new RegExp(`\\bborder-(?:${COLOURS})-(?:100|200|300)\\b`),
    },
];

const args = process.argv.slice(2);
const files = args.length
    ? args.flatMap((a) => globSync(a.replaceAll('\\', '/')))
    : globSync('resources/js/**/*.vue').concat(globSync('templates/**/*.vue'));

let total = 0;

for (const file of [...new Set(files)]) {
    const lines = readFileSync(file, 'utf8').split(/\r?\n/);
    const hits = [];

    lines.forEach((line, i) => {
        // Only inspect attributes, not prose.
        const attrs = line.match(/class="[^"]*"/g);
        if (!attrs) return;

        for (const attr of attrs) {
            for (const { kind, re } of patterns) {
                const found = attr.match(re);
                if (!found) continue;

                // A dark: variant of the same colour is enough to count as covered.
                const covered = found.every((cls) => {
                    const colour = cls.replace(/^(bg|text|border)-/, '');
                    return attr.includes(
                        `dark:${cls.split('-').slice(0, 2).join('-')}-`,
                    );
                });

                if (!covered) {
                    hits.push({
                        line: i + 1,
                        kind,
                        classes: [...new Set(found)],
                    });
                }
            }
        }
    });

    if (hits.length) {
        total += hits.length;
        console.log(`\n${file}  (${hits.length})`);
        for (const h of hits) {
            console.log(`  ${h.line}: ${h.kind} -> ${h.classes.join(', ')}`);
        }
    }
}

console.log(`\n${total} light-only class attributes`);
