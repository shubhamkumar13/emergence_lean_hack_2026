/**
 * @typedef {Object} ClueMetadata
 * @property {number} [row] - The grid row mentioned (1-5).
 * @property {string} [column] - The grid column mentioned (A-D).
 * @property {number} [count] - The number of entities mentioned (e.g., "2 criminals").
 * @property {'criminal' | 'innocent'} [target] - The status of the subjects mentioned.
 * @property {string[]} [subjects] - Names of characters from the grid mentioned in the clue.
 * @property {string[]} [professions] - Professions mentioned in the clue.
 */

/**
 * @typedef {Object} StructuredClue
 * @property {string} text - The raw text of the clue or rule.
 * @property {'clue' | 'rule'} type - 'clue' for puzzle-specific logic, 'rule' for general game mechanics.
 * @property {ClueMetadata} [metadata] - Extracted logical markers and entities.
 */

/**
 * @typedef {Object} GridCard
 * @property {string} coord - Grid position (e.g., "A1", "D5").
 * @property {string} name - The character's name.
 * @property {string} profession - The character's profession.
 * @property {string} face - The emoji representative.
 * @property {string | null} initialClue - Specific clue text found on the card.
 */

/**
 * @typedef {Object} PuzzleData
 * @property {string} date - The ISO date of the scrape (YYYY-MM-DD).
 * @property {string} url - The source URL of the puzzle.
 * @property {StructuredClue[]} clues - Array of structured logical statements and rules.
 * @property {GridCard[]} grid - Array of 20 card objects representing the puzzle grid.
 */

import puppeteer from 'puppeteer';

(async () => {
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();

  await page.goto('https://cluesbysam.com', { waitUntil: 'networkidle0', timeout: 30000 });

  // Click "Start" button
  await page.waitForSelector('button.start', { timeout: 10000 });
  await page.click('button.start');

  // Wait for puzzle content to load
  await page.waitForFunction(
    () => document.body.innerText.includes('criminal') || document.body.innerText.includes('Row'),
    { timeout: 15000 }
  );

  const puzzleData = await page.evaluate(() => {
    // 1. Grid Extraction
    const cards = Array.from(document.querySelectorAll('.card'));
    const grid = cards.map(card => {
      const coord = card.querySelector('.coord')?.textContent?.trim();
      const name = card.querySelector('.name')?.textContent?.trim();
      const profession = card.querySelector('.profession')?.textContent?.trim();
      const face = card.querySelector('.face')?.textContent?.trim();
      const cardText = card.textContent?.trim() || '';
      
      // Extract specific clue text if it exists on the card
      const extra = cardText
        .replace(coord || '', '')
        .replace(name || '', '')
        .replace(profession || '', '')
        .replace(face || '', '')
        .replace('🔎', '')
        .trim();

      return {
        coord,
        name,
        profession,
        face,
        initialClue: extra || null
      };
    });

    // 2. Global Clues Extraction (filtered for logic statements)
    const keywords = ['criminal', 'innocent', 'row', 'column', 'between', 'beside', 'left', 'right', 'above', 'below'];
    const instructionalKeywords = ['goal', 'tap', 'click', 'settings', 'share', 'tutorial', 'copy', 'paste', 'hint', 'long-press', 'newsletter', 'sharing a scenario'];
    
    const allElements = Array.from(document.querySelectorAll('div, p, span, li'));
    const rawClues = allElements
        .map(el => el.textContent?.trim() || '')
        .filter(t => {
          const lower = t.toLowerCase();
          return t.length > 5 && t.length < 500 &&
                 keywords.some(kw => lower.includes(kw)) &&
                 !instructionalKeywords.some(kw => lower.includes(kw));
        });

    // Deduplicate: remove strings that are contained within others or are near-duplicates
    const uniqueRawClues = Array.from(new Set(rawClues)).sort((a, b) => a.length - b.length);
    const filteredClues = uniqueRawClues.filter((clue, index) => {
      return !uniqueRawClues.some((other, otherIndex) => otherIndex < index && clue.includes(other));
    });

    const structuredClues = filteredClues.map(text => {
      const lowerText = text.toLowerCase();
      
      const isRule = 
        lowerText.includes('means') || 
        lowerText.includes('always') || 
        lowerText.includes('everyone') ||
        lowerText.includes('total') ||
        lowerText.includes('more doesn\'t mean') ||
        lowerText.includes('numbers are exact') ||
        lowerText.includes('connected means') ||
        lowerText.includes('rows go sideways') ||
        lowerText.includes('numbered 1,2,3,4,5');

      const type = isRule ? 'rule' : 'clue';
      
      let metadata: any = {};
      if (type === 'clue') {
        const rowMatch = text.match(/row\s*(\d)/i);
        const colMatch = text.match(/column\s*([A-D])/i);
        const countMatch = text.match(/(\d+)/);
        
        if (rowMatch) metadata.row = parseInt(rowMatch[1], 10);
        if (colMatch) metadata.column = colMatch[1].toUpperCase();
        if (countMatch) metadata.count = parseInt(countMatch[1], 10);
        
        if (lowerText.includes('criminal')) metadata.target = 'criminal';
        if (lowerText.includes('innocent')) metadata.target = 'innocent';
        
        // Extract names mentioned in the clue (names from grid) using word boundaries
        const names = Array.from(document.querySelectorAll('.card .name'))
          .map(el => el.textContent?.trim()?.toLowerCase())
          .filter(name => name && new RegExp(`\\b${name}\\b`, 'i').test(text));
        
        if (names.length > 0) metadata.subjects = Array.from(new Set(names));

        // Extract professions
        const professions = Array.from(document.querySelectorAll('.card .profession'))
          .map(el => el.textContent?.trim()?.toLowerCase())
          .filter(prof => prof && new RegExp(`\\b${prof}\\b`, 'i').test(text));
        
        if (professions.length > 0) metadata.professions = Array.from(new Set(professions));
      }

      return {
        text,
        type,
        ...(Object.keys(metadata).length > 0 ? { metadata } : {})
      };
    });

    return {
      date: new Date().toISOString().split('T')[0],
      url: window.location.href,
      clues: structuredClues,
      grid
    };
  });

  // Output structured JSON
  console.log(JSON.stringify(puzzleData, null, 2));

  await browser.close();
})();