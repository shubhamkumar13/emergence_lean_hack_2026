Console.log("Hello, world!")

//  * JSON Structure Overview:
//  * - date: The ISO date of the scrape (YYYY-MM-DD).
//  * - url: The source URL of the puzzle.
//  * - clues: An array of unique logical statements and rules extracted from the page.
//  * - grid: An array of 20 objects, each representing a card in the puzzle:
//  *    - coord: Grid position (e.g., "A1", "D5").
//  *    - name: The character's name.
//  *    - profession: The character's profession.
//  *    - face: The emoji representative.
//  *    - initialClue: Any specific clue text found directly on that card (or null if empty).