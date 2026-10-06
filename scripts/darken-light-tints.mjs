/**
 * Adds the missing `dark:` partner to light-only colour utilities in a class
 * attribute, so a tinted panel or a deep text colour stops glowing on a dark
 * page.
 *
 * Why a script and not hand edits: the mapping is purely mechanical
 * (bg-<colour>-50 pairs with bg-<colour>-950/40 and so on), there are a
 * hundred-odd sites, and a human doing them by hand reliably misses some. The
 * script refuses to touch a class that already has a `dark:` partner, so
 * running it twice changes nothing the second time.
 *
 * Deliberately narrow: it only rewrites plain `class="..."` attributes holding
 * nothing but literal class names. Anything bound with `:class` is left alone,
 * because there the strings are expressions and a regex cannot tell a class
 * name from part of an expression.
 *
 * Run with --check to report without writing.
 *
 * Usage: node scripts/darken-light-tints.mjs [--check] <glob...>
 */
import { globSync, readFileSync, writeFileSync } from 'node:fs';

const COLOURS =
    'amber|green|blue|yellow|red|emerald|orange|sky|indigo|purple|pink|teal|cyan|violet|rose|lime';

/**
 * The light utility, and the utility to pair it with in dark mode. Values do
 * not carry the `dark:` prefix -- the caller places it.
 *
 * Tints get a translucent 950 wash rather than a solid colour: these panels sit
 * on an already-dark surface, and a solid 950 inside a card is a black hole.
 */
const RULES = [
    {
        re: new RegExp(`^bg-(${COLOURS})-(50|100)$`),
        to: (m) => `bg-${m[1]}-950/40`,
    },
    { re: new RegExp(`^bg-(${COLOURS})-200$`), to: (m) => `bg-${m[1]}-900/60` },
    {
        re: new RegExp(`^text-(${COLOURS})-700$`),
        to: (m) => `text-${m[1]}-300`,
    },
    {
        re: new RegExp(`^text-(${COLOURS})-800$`),
        to: (m) => `text-${m[1]}-200`,
    },
    {
        re: new RegExp(`^text-(${COLOURS})-900$`),
        to: (m) => `text-${m[1]}-100`,
    },
    {
        re: new RegExp(`^border-(${COLOURS})-(100|200|300)$`),
        to: (m) => `border-${m[1]}-800`,
    },
];

const check = process.argv.includes('--check');
const globs = process.argv.slice(2).filter((a) => !a.startsWith('--'));

if (!globs.length) {
    console.error('No globs given.');
    process.exit(1);
}

const files = [
    ...new Set(globs.flatMap((g) => globSync(g.replaceAll('\\', '/')))),
];

/** The `prefix-colour` stem of a utility, e.g. `bg-amber-50` -> `bg-amber`. */
function stem(utility) {
    const parts = utility.split(':').pop().split('-');
    return parts.slice(0, 2).join('-');
}

/** Rewrites one literal class attribute. Returns the attribute value. */
function transform(value) {
    const classes = value.split(/\s+/).filter(Boolean);
    const out = [];

    for (const cls of classes) {
        out.push(cls);

        if (cls.startsWith('-')) continue;

        // hover:bg-blue-50 -> variants [hover], utility bg-blue-50
        const parts = cls.split(':');
        const utility = parts.pop();
        const variants = parts;

        for (const rule of RULES) {
            const match = utility.match(rule.re);
            if (!match) continue;

            const partner = rule.to(match);

            // Already has a dark variant of this colour: leave it alone.
            if (out.some((c) => c.includes(`dark:${stem(utility)}-`))) break;

            // `dark` goes first: dark:hover:... is the order Tailwind uses.
            out.push(['dark', ...variants, partner].join(':'));
            break;
        }
    }

    return out.join(' ');
}

let changedFiles = 0;
let changedAttrs = 0;

for (const file of files) {
    const source = readFileSync(file, 'utf8');
    let hits = 0;

    // Plain class only. The negative lookbehind skips `:class`, and the value
    // pattern rejects anything containing a quote, brace or bracket, which is
    // what a bound expression looks like.
    const next = source.replace(
        /(?<!:)\bclass="([^"'{}[\]]*)"/g,
        (match, value) => {
            const rewritten = transform(value);
            if (rewritten === value) return match;
            hits++;
            return `class="${rewritten}"`;
        },
    );

    if (hits) {
        changedFiles++;
        changedAttrs += hits;
        console.log(`${check ? 'would change' : 'changed'}: ${file} (${hits})`);
        if (!check) writeFileSync(file, next, 'utf8');
    }
}

console.log(
    `\n${changedAttrs} class attributes across ${changedFiles} files (${check ? 'dry run' : 'written'})`,
);
