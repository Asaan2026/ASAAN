/**
 * Appends translation keys to the storefront dictionaries without rewriting
 * the rest of the file.
 *
 * Why not parse and re-serialise: these files carry keys that differ only by
 * case ("Clear Filters" and "Clear filters"), which JSON.parse collapses to
 * one. Round-tripping would silently delete one of them. So this reads the
 * file as text, finds the final closing brace, and splices the new entries in
 * just before it.
 *
 * Usage: node scripts/add-translations.mjs
 */
import { readFileSync, writeFileSync } from 'node:fs';

/** key -> [english, dari, pashto] */
const KEYS = {
    Light: ['Light', 'روشن', 'روښانه'],
    Dark: ['Dark', 'تاریک', 'تیره'],
    System: ['System', 'سیستم', 'سیسټم'],
    'Colour theme': ['Colour theme', 'پوسته رنگ', 'د رنګ ډیزاین'],
    Appearance: ['Appearance', 'ظاهر', 'ښکاره'],
    'Switch to light mode': [
        'Switch to light mode',
        'تغییر به حالت روشن',
        'روښانه حالت ته بدلول',
    ],
    'Switch to dark mode': [
        'Switch to dark mode',
        'تغییر به حالت تاریک',
        'تیره حالت ته بدلول',
    ],
    Currency: ['Currency', 'واحد پول', 'پولي واحد'],
    'Choose whether the site is light or dark, or follow your device.': [
        'Choose whether the site is light or dark, or follow your device.',
        'انتخاب کنید که سایت روشن باشد یا تاریک، یا مطابق دستگاه شما باشد.',
        'وټاکئ چې سایټ روښانه وي یا تیره، یا د وسیلې له مخه راګځول شوی.',
    ],
    'Change currency, currently {code}': [
        'Change currency, currently {code}',
        'تغییر واحد پول، در حال حاضر {code}',
        'د پولي واحد بدلول، اوس {code}',
    ],
    'Display Language': [
        'Display Language',
        'زبان نمایش',
        'د ښکاره ژبه',
    ],
    'Choose the language the site is shown to you in.': [
        'Choose the language the site is shown to you in.',
        'انتخاب کنید که سایت به چه زبانی به شما نمایش داده شود.',
        'وټاکئ چې سایټ تاسو ته په کوم ژبه ښکاره شي.',
    ],
};

const LANGS = ['en', 'fa', 'ps'];

/** Escapes a value for a JSON string, quotes and backslashes included. */
function json(value) {
    return JSON.stringify(value);
}

for (const [index, lang] of LANGS.entries()) {
    const path = `lang/${lang}/storefront.json`;
    const source = readFileSync(path, 'utf8');

    const closing = source.lastIndexOf('}');
    if (closing === -1) throw new Error(`${path}: no closing brace found`);

    const head = source.slice(0, closing).trimEnd();
    const tail = source.slice(closing);

    const existing = new Set(Object.keys(JSON.parse(source)));
    const additions = Object.entries(KEYS)
        .filter(([key]) => !existing.has(key))
        .map(([key, values]) => `    ${json(key)}: ${json(values[index])}`);

    if (!additions.length) {
        console.log(`${path}: already up to date`);
        continue;
    }

    // The block before the brace ends with a newline after the last comma,
    // or with the last entry when there is no trailing comma.
    const needsComma = !head.trimEnd().endsWith(',');
    const block = head + (needsComma ? ',' : '') + '\n' + additions.join(',\n') + '\n';

    writeFileSync(path, block + tail, 'utf8');
    console.log(`${path}: added ${additions.length} keys`);
}