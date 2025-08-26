#!/usr/bin/env node
/**
 * ================================================================
 * HEIC to JPEG Converter (Node.js)
 * ================================================================
 * 
 * This script converts all HEIC files in a specified directory to JPEG format
 * using ImageMagick. Requires ImageMagick to be installed and in system PATH.
 * 
 * USAGE:
 *   node convert_heic_to_jpeg.js [folder_path] [delete]
 *   
 *   folder_path - Target directory (optional, defaults to current folder)
 *   delete      - Pass "delete" to remove original HEIC files after conversion
 * 
 * EXAMPLES:
 *   node convert_heic_to_jpeg.js                              - Convert files in current folder
 *   node convert_heic_to_jpeg.js delete                       - Convert and delete originals in current folder
 *   node convert_heic_to_jpeg.js "C:\Users\Name\Pictures"     - Convert files in specified folder
 *   node convert_heic_to_jpeg.js "./Photos"                   - Convert files in subfolder
 *   node convert_heic_to_jpeg.js "./Photos" delete            - Convert and delete originals in subfolder
 * 
 * REQUIREMENTS:
 *   - Node.js installed
 *   - ImageMagick must be installed with HEIC support
 *   - Download from: https://imagemagick.org/script/download.php
 * 
 * OUTPUT:
 *   - Creates JPEG files with same names as original HEIC files
 *   - Original HEIC files are preserved by default (unless delete option is used)
 *   - JPEG quality is set to 90%
 * 
 * Generated with Claude AI on August 26, 2025
 * ================================================================
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ANSI color codes for console output
const colors = {
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    cyan: '\x1b[36m',
    reset: '\x1b[0m',
    bright: '\x1b[1m'
};

// Helper function for colored console output
function colorLog(message, color = '') {
    console.log(`${color}${message}${colors.reset}`);
}

async function main() {
    colorLog('HEIC to JPEG Converter (Node.js)', colors.bright + colors.green);
    colorLog('====================================', colors.bright + colors.green);
    console.log();

    // Parse command line arguments
    const args = process.argv.slice(2);
    let targetFolder = process.cwd();
    let deleteOriginals = false;

    // Parse arguments
    if (args.length === 0) {
        // No arguments - use current directory, preserve files
        colorLog(`Using current directory: ${targetFolder}`, colors.cyan);
        colorLog('Preserve mode: Original HEIC files will be kept', colors.cyan);
    } else if (args.length === 1) {
        if (args[0].toLowerCase() === 'delete') {
            // Only delete argument - use current directory, delete files
            deleteOriginals = true;
            colorLog(`Using current directory: ${targetFolder}`, colors.cyan);
            colorLog('Delete mode: Original HEIC files will be deleted after successful conversion', colors.yellow);
        } else {
            // Only folder argument - use specified directory, preserve files
            targetFolder = path.resolve(args[0]);
            colorLog(`Using specified directory: ${targetFolder}`, colors.cyan);
            colorLog('Preserve mode: Original HEIC files will be kept', colors.cyan);
        }
    } else if (args.length === 2) {
        // Both folder and delete arguments
        targetFolder = path.resolve(args[0]);
        if (args[1].toLowerCase() === 'delete') {
            deleteOriginals = true;
        }
        colorLog(`Using specified directory: ${targetFolder}`, colors.cyan);
        if (deleteOriginals) {
            colorLog('Delete mode: Original HEIC files will be deleted after successful conversion', colors.yellow);
        } else {
            colorLog('Preserve mode: Original HEIC files will be kept', colors.cyan);
        }
    }

    console.log();

    // Check if ImageMagick is installed
    try {
        execSync('magick -version', { stdio: 'pipe' });
    } catch (error) {
        colorLog('ERROR: ImageMagick not found or not in PATH', colors.red);
        colorLog('Please install ImageMagick and ensure it\'s in your system PATH', colors.red);
        colorLog('Download from: https://imagemagick.org/script/download.php', colors.red);
        process.exit(1);
    }

    // Test HEIC support
    try {
        const formatList = execSync('magick -list format', { encoding: 'utf8' });
        if (!formatList.toLowerCase().includes('heic')) {
            colorLog('WARNING: HEIC format may not be supported by your ImageMagick installation', colors.yellow);
            colorLog('This could cause conversion errors', colors.yellow);
            console.log();
        }
    } catch (error) {
        colorLog('WARNING: Could not verify HEIC support', colors.yellow);
        console.log();
    }

    // Check if target directory exists
    if (!fs.existsSync(targetFolder)) {
        colorLog(`ERROR: Directory "${targetFolder}" does not exist`, colors.red);
        process.exit(1);
    }

    // Check if target is actually a directory
    if (!fs.lstatSync(targetFolder).isDirectory()) {
        colorLog(`ERROR: "${targetFolder}" is not a directory`, colors.red);
        process.exit(1);
    }

    // Find all HEIC files in the target directory
    let heicFiles;
    try {
        const allFiles = fs.readdirSync(targetFolder);
        heicFiles = allFiles.filter(file => 
            file.toLowerCase().endsWith('.heic') && 
            fs.lstatSync(path.join(targetFolder, file)).isFile()
        );
    } catch (error) {
        colorLog(`ERROR: Cannot read directory "${targetFolder}"`, colors.red);
        colorLog(`Details: ${error.message}`, colors.red);
        process.exit(1);
    }

    if (heicFiles.length === 0) {
        colorLog('No HEIC files found in target directory', colors.yellow);
        process.exit(0);
    }

    colorLog(`Found ${heicFiles.length} HEIC file(s) to convert`, colors.green);
    console.log();

    // Convert each HEIC file to JPEG
    let converted = 0;
    let failed = 0;

    for (const fileName of heicFiles) {
        const inputPath = path.join(targetFolder, fileName);
        const baseName = path.parse(fileName).name;
        const outputPath = path.join(targetFolder, `${baseName}.jpg`);

        colorLog(`Converting: ${fileName}`, colors.cyan);

        let conversionSuccess = false;

        try {
            // Try different conversion approaches
            try {
                // First try: Direct conversion
                execSync(`magick "${inputPath}" -quality 90 "${outputPath}"`, { stdio: 'pipe' });
                conversionSuccess = true;
            } catch (error1) {
                try {
                    // If that fails, try with explicit format specification
                    console.log('  Retrying with format specification...');
                    execSync(`magick heic:"${inputPath}" -quality 90 "${outputPath}"`, { stdio: 'pipe' });
                    conversionSuccess = true;
                } catch (error2) {
                    try {
                        // If still failing, try with different options
                        console.log('  Retrying with alternative options...');
                        execSync(`magick "${inputPath}" -auto-orient -quality 90 "${outputPath}"`, { stdio: 'pipe' });
                        conversionSuccess = true;
                    } catch (error3) {
                        throw error3;
                    }
                }
            }

            if (conversionSuccess) {
                colorLog(`  SUCCESS: Created ${baseName}.jpg`, colors.green);
                converted++;

                // Delete original file if delete mode is enabled
                if (deleteOriginals) {
                    try {
                        fs.unlinkSync(inputPath);
                        colorLog(`  DELETED: Removed original file ${fileName}`, colors.yellow);
                    } catch (deleteError) {
                        colorLog(`  WARNING: Could not delete original file ${fileName}`, colors.yellow);
                        colorLog(`  Details: ${deleteError.message}`, colors.yellow);
                    }
                }
            }
        } catch (error) {
            colorLog(`  ERROR: Failed to convert ${fileName}`, colors.red);
            colorLog(`  Details: ${error.message}`, colors.red);
            failed++;
        }

        console.log();
    }

    colorLog('Conversion complete!', colors.bright + colors.green);
    colorLog(`Files converted successfully: ${converted}`, colors.green);
    if (failed > 0) {
        colorLog(`Files that failed: ${failed}`, colors.red);
    }
}

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    colorLog(`\nUnexpected error: ${error.message}`, colors.red);
    process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
    colorLog(`\nUnhandled rejection at: ${promise}, reason: ${reason}`, colors.red);
    process.exit(1);
});

// Run the main function
main().catch((error) => {
    colorLog(`Error: ${error.message}`, colors.red);
    process.exit(1);
});