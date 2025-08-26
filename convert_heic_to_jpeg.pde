/**
 * ================================================================
 * HEIC to JPEG Converter (Processing)
 * ================================================================
 * 
 * This Processing sketch converts all HEIC files in a specified directory 
 * to JPEG format using ImageMagick command-line tool.
 * 
 * SETUP:
 *   1. Set TARGET_FOLDER to your desired directory path
 *   2. Set DELETE_ORIGINALS to true if you want to delete original files
 *   3. Run the sketch
 * 
 * REQUIREMENTS:
 *   - Processing IDE
 *   - ImageMagick must be installed with HEIC support
 *   - Download from: https://imagemagick.org/script/download.php
 * 
 * CONFIGURATION:
 *   Modify the variables below to customize behavior:
 *   - TARGET_FOLDER: Directory containing HEIC files
 *   - DELETE_ORIGINALS: Whether to delete original files after conversion
 *   - JPEG_QUALITY: JPEG compression quality (1-100)
 * 
 * OUTPUT:
 *   - Creates JPEG files with same names as original HEIC files
 *   - Original HEIC files are preserved by default
 *   - Progress is shown in the Processing console and on canvas
 * 
 * Generated with Claude AI on August 26, 2025
 * ================================================================
 */

// Configuration - DEFAULT VALUES (can be changed via UI)
String TARGET_FOLDER = ""; // Leave empty for sketch folder, or set path like "C:\\Photos" or "/Users/name/Pictures"
boolean DELETE_ORIGINALS = false; // Set to true to delete original files after successful conversion
int JPEG_QUALITY = 90; // JPEG quality (1-100, higher = better quality)

// Internal variables
ArrayList<String> heicFiles;
int currentFileIndex = 0;
boolean isConverting = false;
boolean conversionComplete = false;
int convertedCount = 0;
int failedCount = 0;
String currentStatus = "";
PFont font;

// UI elements
Button folderSelectButton;
Button startButton;
Checkbox deleteCheckbox;
boolean uiInitialized = false;
boolean filesScanned = false;

void setup() {
  size(800, 600);
  background(40);
  
  // Try to load a font, fallback to default if not available
  try {
    font = createFont("Arial", 16);
    textFont(font);
  } catch (Exception e) {
    // Use default font if Arial is not available
  }
  
  textAlign(LEFT);
  
  println("HEIC to JPEG Converter (Processing)");
  println("====================================");
  println();
  
  // Initialize UI elements
  folderSelectButton = new Button(50, 160, 200, 35, "Select Folder");
  deleteCheckbox = new Checkbox(50, 210, "Delete original files after conversion");
  startButton = new Button(50, 260, 150, 35, "Start Conversion");
  startButton.enabled = false; // Disabled until folder is selected and files are found
  
  // Check if ImageMagick is available
  if (!checkImageMagick()) {
    currentStatus = "ERROR: ImageMagick not found!";
    println(currentStatus);
    println("Please install ImageMagick and ensure it's in your system PATH");
    return;
  }
  
  currentStatus = "Select a folder to scan for HEIC files";
  uiInitialized = true;
  
  // If TARGET_FOLDER is preset, scan it
  if (!TARGET_FOLDER.isEmpty()) {
    scanFolder(TARGET_FOLDER);
  }
}

void draw() {
  background(40);
  fill(255);
  
  // Title
  textSize(24);
  text("HEIC to JPEG Converter", 50, 50);
  
  textSize(16);
  
  // Configuration info
  String folderDisplay = TARGET_FOLDER.isEmpty() ? "No folder selected" : TARGET_FOLDER;
  text("Target: " + folderDisplay, 50, 100);
  text("JPEG Quality: " + JPEG_QUALITY + "%", 50, 120);
  
  // Draw UI elements if initialized
  if (uiInitialized) {
    folderSelectButton.draw();
    deleteCheckbox.draw();
    startButton.draw();
  }
  
  // Status
  fill(220, 220, 100);
  text("Status: " + currentStatus, 50, 320);
  
  if (filesScanned && heicFiles != null && heicFiles.size() > 0) {
    // Progress info
    fill(255);
    text("Files found: " + heicFiles.size(), 50, 360);
    text("Converted: " + convertedCount, 50, 380);
    text("Failed: " + failedCount, 50, 400);
    
    if (isConverting && currentFileIndex < heicFiles.size()) {
      // Progress bar
      float progress = (float)currentFileIndex / heicFiles.size();
      fill(100);
      rect(50, 440, 500, 20);
      fill(100, 200, 100);
      rect(50, 440, progress * 500, 20);
      
      // Current file
      fill(255);
      text("Converting: " + new File(heicFiles.get(currentFileIndex)).getName(), 50, 480);
    }
    
    if (conversionComplete) {
      fill(100, 255, 100);
      textSize(18);
      text("Conversion Complete!", 50, 520);
      textSize(16);
      fill(255);
      text("Successfully converted: " + convertedCount, 50, 550);
      if (failedCount > 0) {
        fill(255, 100, 100);
        text("Failed conversions: " + failedCount, 50, 570);
      }
    }
  } else if (filesScanned && (heicFiles == null || heicFiles.size() == 0)) {
    fill(255, 200, 100);
    text("No HEIC files found in selected folder", 50, 360);
  }
}

void mousePressed() {
  if (!uiInitialized) return;
  
  // Check button clicks
  if (folderSelectButton.isClicked(mouseX, mouseY)) {
    selectFolder("Select folder containing HEIC files:", "folderSelected");
  }
  
  if (deleteCheckbox.isClicked(mouseX, mouseY)) {
    DELETE_ORIGINALS = deleteCheckbox.checked;
    println("Delete mode: " + (DELETE_ORIGINALS ? "ON" : "OFF"));
  }
  
  if (startButton.isClicked(mouseX, mouseY) && startButton.enabled) {
    if (!isConverting && !conversionComplete && heicFiles != null && heicFiles.size() > 0) {
      isConverting = true;
      currentStatus = "Converting files...";
      thread("convertFiles");
    }
  }
}

void folderSelected(File selection) {
  if (selection == null) {
    println("No folder selected");
    currentStatus = "No folder selected";
  } else {
    TARGET_FOLDER = selection.getAbsolutePath();
    println("Selected folder: " + TARGET_FOLDER);
    scanFolder(TARGET_FOLDER);
  }
}

void scanFolder(String folderPath) {
  currentStatus = "Scanning folder for HEIC files...";
  
  // Reset conversion state
  isConverting = false;
  conversionComplete = false;
  convertedCount = 0;
  failedCount = 0;
  currentFileIndex = 0;
  
  // Find HEIC files
  heicFiles = findHeicFiles(folderPath);
  filesScanned = true;
  
  if (heicFiles.size() == 0) {
    currentStatus = "No HEIC files found in selected folder";
    startButton.enabled = false;
  } else {
    currentStatus = "Found " + heicFiles.size() + " HEIC file(s). Ready to convert!";
    startButton.enabled = true;
    println("Found " + heicFiles.size() + " HEIC file(s) to convert");
  }
}

void convertFiles() {
  for (int i = 0; i < heicFiles.size(); i++) {
    currentFileIndex = i;
    String inputPath = heicFiles.get(i);
    File inputFile = new File(inputPath);
    String fileName = inputFile.getName();
    String baseName = fileName.substring(0, fileName.lastIndexOf('.'));
    String outputPath = inputFile.getParent() + File.separator + baseName + ".jpg";
    
    println("Converting: " + fileName);
    currentStatus = "Converting: " + fileName;
    
    boolean success = convertSingleFile(inputPath, outputPath);
    
    if (success) {
      println("  SUCCESS: Created " + baseName + ".jpg");
      convertedCount++;
      
      if (DELETE_ORIGINALS) {
        try {
          if (inputFile.delete()) {
            println("  DELETED: Removed original file " + fileName);
          } else {
            println("  WARNING: Could not delete original file " + fileName);
          }
        } catch (Exception e) {
          println("  WARNING: Error deleting original file - " + e.getMessage());
        }
      }
    } else {
      println("  ERROR: Failed to convert " + fileName);
      failedCount++;
    }
    
    // Small delay to make progress visible
    try {
      Thread.sleep(100);
    } catch (InterruptedException e) {
      // Continue
    }
  }
  
  currentFileIndex = heicFiles.size();
  isConverting = false;
  conversionComplete = true;
  currentStatus = "Conversion complete!";
  
  println();
  println("Conversion complete!");
  println("Files converted successfully: " + convertedCount);
  if (failedCount > 0) {
    println("Files that failed: " + failedCount);
  }
}

boolean checkImageMagick() {
  try {
    Process process = Runtime.getRuntime().exec("magick -version");
    process.waitFor();
    return process.exitValue() == 0;
  } catch (Exception e) {
    return false;
  }
}

ArrayList<String> findHeicFiles(String folderPath) {
  ArrayList<String> files = new ArrayList<String>();
  File folder = new File(folderPath);
  
  if (!folder.exists() || !folder.isDirectory()) {
    println("ERROR: Directory does not exist or is not accessible: " + folderPath);
    return files;
  }
  
  File[] listOfFiles = folder.listFiles();
  if (listOfFiles != null) {
    for (File file : listOfFiles) {
      if (file.isFile()) {
        String fileName = file.getName().toLowerCase();
        if (fileName.endsWith(".heic")) {
          files.add(file.getAbsolutePath());
        }
      }
    }
  }
  
  return files;
}

boolean convertSingleFile(String inputPath, String outputPath) {
  try {
    // Try different conversion approaches
    String[] commands = {
      "magick \"" + inputPath + "\" -quality " + JPEG_QUALITY + " \"" + outputPath + "\"",
      "magick heic:\"" + inputPath + "\" -quality " + JPEG_QUALITY + " \"" + outputPath + "\"",
      "magick \"" + inputPath + "\" -auto-orient -quality " + JPEG_QUALITY + " \"" + outputPath + "\""
    };
    
    for (String command : commands) {
      try {
        Process process = Runtime.getRuntime().exec(command);
        int exitCode = process.waitFor();
        
        if (exitCode == 0) {
          return true; // Success
        }
      } catch (Exception e) {
        // Try next command
        continue;
      }
    }
    
    return false; // All attempts failed
  } catch (Exception e) {
    println("Exception during conversion: " + e.getMessage());
    return false;
  }
}

// UI Classes - Button
class Button {
  float x, y, w, h;
  String label;
  boolean enabled = true;
  boolean hovered = false;
  
  Button(float x, float y, float w, float h, String label) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
  }
  
  void draw() {
    // Update hover state
    hovered = mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
    
    // Draw button
    if (enabled) {
      if (hovered) {
        fill(80, 120, 200);
        stroke(100, 150, 255);
      } else {
        fill(60, 100, 180);
        stroke(80, 120, 220);
      }
    } else {
      fill(60);
      stroke(100);
    }
    
    strokeWeight(2);
    rect(x, y, w, h, 5);
    
    // Draw label
    fill(enabled ? 255 : 150);
    textAlign(CENTER, CENTER);
    textSize(14);
    text(label, x + w/2, y + h/2);
    textAlign(LEFT); // Reset text alignment
  }
  
  boolean isClicked(float mx, float my) {
    return enabled && mx >= x && mx <= x + w && my >= y && my <= y + h;
  }
}

// UI Classes - Checkbox
class Checkbox {
  float x, y;
  String label;
  boolean checked = false;
  boolean hovered = false;
  float boxSize = 20;
  
  Checkbox(float x, float y, String label) {
    this.x = x;
    this.y = y;
    this.label = label;
    this.checked = DELETE_ORIGINALS; // Initialize with current value
  }
  
  void draw() {
    // Update hover state
    hovered = mouseX >= x && mouseX <= x + boxSize + textWidth(label) + 10 && 
              mouseY >= y && mouseY <= y + boxSize;
    
    // Draw checkbox
    if (hovered) {
      fill(80);
      stroke(150);
    } else {
      fill(60);
      stroke(120);
    }
    
    strokeWeight(2);
    rect(x, y, boxSize, boxSize, 3);
    
    // Draw checkmark if checked
    if (checked) {
      stroke(100, 255, 100);
      strokeWeight(3);
      line(x + 5, y + boxSize/2, x + boxSize/2, y + boxSize - 5);
      line(x + boxSize/2, y + boxSize - 5, x + boxSize - 3, y + 3);
    }
    
    // Draw label
    fill(255);
    textAlign(LEFT, CENTER);
    textSize(14);
    text(label, x + boxSize + 10, y + boxSize/2);
  }
  
  boolean isClicked(float mx, float my) {
    if (mx >= x && mx <= x + boxSize + textWidth(label) + 10 && 
        my >= y && my <= y + boxSize) {
      checked = !checked;
      return true;
    }
    return false;
  }
}