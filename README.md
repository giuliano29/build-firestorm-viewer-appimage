Firestorm Viewer AppImage Build Script 🚀

This repository provides an automation script to create a portable Firestorm Viewer AppImage for Linux. It is designed to ensure stability and compatibility across modern distributions, particularly focusing on legacy support and visual consistency.
✨ Key Features

    🎙️ SLVoice Stability (32-bit): The script automatically fetches and injects libidn11 and other 32-bit dependencies from Debian archives to ensure spatial voice works correctly.

    🎨 Visual Consistency: Includes GTK2 engines (Murrine and Pixbuf) within the AppImage, allowing the viewer to correctly render custom themes like Catppuccin regardless of the host system's libraries.

    🧠 Advanced Memory Management: Integrates jemalloc to optimize RAM usage, which is essential for maintaining stability in high-density virtual environments like the FarmverseGrid.

    📦 Fully Self-Contained: Packages all necessary libraries into a single executable, preventing "dependency hell" when updating your Linux distribution.

🛠️ Prerequisites

To run the build script, ensure you have the following:

    Firestorm Binaries: The extracted source folder of the viewer (e.g., Phoenix-Firestorm-Releasex64...).

    System Tools: wget and dpkg-deb installed on your host system.

    AppImageTool: The appimagetool-x86_64.AppImage executable must be present in the same directory as the script.

🚀 Usage Instructions

    Configure the Script: Open build-firestorm-viewer-appimage.sh and ensure the SOURCE_DIR variable matches your extracted Firestorm folder name.

    Set Permissions:
    Bash

chmod +x build-firestorm-viewer-appimage.sh

Run the Build:
Bash

    ./build-firestorm-viewer-appimage.sh

    Deployment: Once finished, your portable Firestorm_Viewer_Online_Build.AppImage will be ready in the root directory.

⚙️ Technical Environment

The generated AppRun handles the following environment configurations automatically:

    LD_LIBRARY_PATH: Prioritizes bundled 32-bit and 64-bit libraries to ensure the internal components (like Voice) use the correct versions.

    GDK_BACKEND=x11: Forced for maximum compatibility with modern display servers.

    GTK_PATH: Pointed to internal engines for consistent UI rendering.

Developed by: Giuliano (Noturno).
