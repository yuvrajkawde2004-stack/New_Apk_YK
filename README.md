# RetailFlow POS - Premium Shop Management System 🚀

**RetailFlow POS** is a modern, fully-featured Point of Sale (POS) and inventory management mobile application designed for retail shops, businesses, and service providers. Built with Flutter, it offers a premium user experience with offline-first capabilities and cloud-sync readiness.

---

## 🌟 Key Features

### 1. 🛒 Advanced Billing & Invoicing
*   **Fast Checkout:** Create bills quickly with an intuitive interface.
*   **Multiple Invoice Themes:** Generate professional invoices in various themes (Classic GST, Premium Gold, Modern Emerald, Royal Violet, Minimal Slate).
*   **Thermal Printer Support:** Connect and print directly to 80mm Bluetooth Thermal POS Printers.
*   **PDF Generation & Sharing:** Instantly generate PDF invoices and share them via WhatsApp or email.

### 2. 📦 Smart Inventory Management
*   **Real-time Stock Tracking:** Automatically updates stock upon every sale.
*   **Low Stock Alerts:** Get notified when product quantities fall below a safe threshold.
*   **Supplier Tracking:** Manage suppliers, purchase costs, and selling prices.

### 3. 👥 Customer & Khata (Ledger) Management
*   **Customer Profiles:** Maintain detailed profiles for each customer.
*   **Due Tracking:** Track outstanding balances and credit (Udhaari) for customers.
*   **Receive Payments:** A premium payment UI to accept partial or full payments against specific pending invoices (Cash, UPI, Card, Bank Transfer).

### 4. 📊 Powerful Reports & Analytics
*   **Dashboard Insights:** View today's sales, revenue, and active customers at a glance.
*   **Gross Profit Calculation:** Accurate profit calculation based on actual sold items `(Selling Price - Purchase Rate) * Quantity`.
*   **Time-based Reports:** Analyze sales and profits over Daily, Weekly, Monthly, and 'All Time' periods.

### 5. ⚙️ System & Security
*   **Offline-First Architecture:** Works seamlessly without an internet connection using local SQLite database.
*   **Cloud Sync Ready:** Integrated with Cloudflare D1 architecture for backing up data to the cloud (Future update).
*   **OTP Authentication:** Secure login system using Email or Mobile Number.
*   **Data Reset:** Secure option to wipe data when logging out to protect privacy.

---

## 🛠️ Technology Stack

*   **Frontend:** Flutter & Dart (Cross-platform UI)
*   **Local Database:** `sqflite` (SQLite for Flutter)
*   **State Management:** Provider
*   **Styling:** Google Fonts (`Outfit`), Custom color palettes
*   **Invoicing:** `pdf` package for generation, `screenshot` for image-based sharing
*   **Backend / Cloud:** Cloudflare Workers API & D1 Database (For Sync)

---

## 🚀 How to Run the Project (Step-by-Step)

### Prerequisites
1. Install [Flutter SDK](https://flutter.dev/docs/get-started/install).
2. Install Android Studio or VS Code with Flutter plugins.
3. Ensure you have an Android Emulator running or a physical Android device connected via USB/Wi-Fi debugging.

### Setup Steps
**Step 1: Clone the repository**
```bash
git clone <repository_url>
cd New_Apk_YK-main/New_Apk_YK-main
```

**Step 2: Get Flutter Dependencies**
```bash
flutter pub get
```

**Step 3: Run the Application**
```bash
flutter run
```

---

## 📂 Project Structure Overview

*   `lib/core/` - Core utilities, themes, localizations, and `database_helper.dart` (SQLite schema & queries).
*   `lib/features/auth/` - OTP Login and authentication screens.
*   `lib/features/dashboard/` - Main home screen, quick actions, and summary stats.
*   `lib/features/billing/` - Cart management, checkout, and invoice templates.
*   `lib/features/inventory/` - Product lists, stock updates, and supplier data.
*   `lib/features/customers/` - Customer lists, profiles, and payment receipt logic.
*   `lib/features/reports/` - Revenue and profit analytics.
*   `lib/features/settings/` - App settings, printer config, and data management.

---

## 🛡️ License
This project is proprietary and confidential. Unauthorized copying or distribution of this codebase is strictly prohibited.
