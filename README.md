# **Simple Damage Meter Addon** 📊💥

## **Overview** 🧐

Welcome to the **Simple Damage Meter** project! This ongoing personal learning project explores the exciting world of **World of Warcraft** addon development. The primary goal is not to compete with massive, feature-rich addons, but rather to provide a **simple** and **lightweight solution** for players—especially those with low-end PCs—who need minimal resource usage while still being able to track important data, like damage done in combat. 

## **Purpose** 🎯

The main goal of this addon is to **track and display the total damage** done by players in a group or raid. It’s designed to use **minimal resources** and offer a **clean, intuitive interface**. Right now, the functionality is focused on showing **damage data**, but future updates will include more advanced features, such as **UI customization** and detailed **damage statistics**.

## **Why Lightweight?** ⚙️

This addon is built with **low-end PC players** in mind. It uses **minimal system resources**, so even players with older hardware can benefit from this tool without worrying about performance issues. The focus is on **simplicity**, **intuitiveness**, and **optimized resource consumption**.

---

## **📜 Changelog** 

### **Version 1.000 - Damage Calculation for You and Your Team** 💥
- Introduced basic **damage calculation** for the player and their team.
- Tracks **damage done** by players in a group or raid, with individual breakdowns.
- Displays damage in a **clean, easy-to-read format** with player names and class icons.

### **Version 1.002 - Updated UI and Functionality** 🎉
- Implemented a **movable and draggable frame** for the damage meter display.
- Added a **clickable icon** to toggle the visibility of the damage meter frame.
- Improved **UI updates** to reflect damage statistics during combat.
- **Fixed the positioning** of the icon to remain around the mini-map.

### **Patch Notes V1.003 ✨**
- **🗺️ Minimap Icon**: Added for quick access to toggle the damage meter UI.
- **⚔️ Spec Icons**: Replaced class icons with spec-specific icons for better role representation.
- **🎨 Dynamic Class-Colored Bars**: Player bars now adjust based on group size with class colors.
- **🔄 Resizing UI**: The UI adapts dynamically as players join or leave, maintaining a clean layout.

#### **Bug Fixes & Enhancements**:
- 🛠️ Improved frame resizing when players join/leave.
- 🎨 Corrected class color definitions for accuracy.

#### **Quality of Life**:
- 🧹 Simplified UI with class-colored bars replacing the fixed background.
- 🚫 Removed XML file for a cleaner Lua-based addon.

### **v1.004 - Movable Frame, Class Icons, & Wave Reset Latest 🎮✨**

New Features and Improvements:
Movable Frame 🖱️:

The damage meter frame is now fully movable and draggable. Users can adjust its position on the screen according to their preference. 🔄

Class Icon 🛡️:

Replaced the spec icon with the class icon for each player. This enhances the visual clarity of player roles and is more intuitive. 👨‍⚖️👩‍⚖️

Clean UI 🎨:

Refined the user interface for a cleaner, more streamlined look. The frame and player elements now have improved spacing and layout for better readability. 📐

Damage Meter Reset on Wave Transition ⚔️:

After killing a wave of mobs and starting a new wave, the damage meter now resets automatically, ensuring that the data only reflects the current wave of combat. 🏆

Toggle Button Next to Minimap 🗺️:

Added a toggle button for the damage meter right next to the minimap. This ensures the button doesn’t obscure other UI elements and can be used without disrupting gameplay. 🎮

Future Plans: In the future, this button will have more freedom for dragging around the minimap. 🔄

Bug Fixes 🐞:
Wave Transition Issue ⚠️: Fixed the issue where the damage meter would not reset properly after a new wave of mobs. ✅

Other Changes 🔧:
Minor performance optimizations to improve the overall user experience. 🚀
