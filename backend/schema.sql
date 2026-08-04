-- Users table
CREATE TABLE IF NOT EXISTS users (
  user_id TEXT PRIMARY KEY,
  mobile TEXT UNIQUE,
  email TEXT UNIQUE,
  name TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  status TEXT DEFAULT 'active'
);

-- Shops table
CREATE TABLE IF NOT EXISTS shops (
  shop_id TEXT PRIMARY KEY,
  owner_id TEXT REFERENCES users(user_id),
  shop_name TEXT NOT NULL,
  address TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- User-Shop mapping (for multi-shop support / staff)
CREATE TABLE IF NOT EXISTS shop_users (
  id TEXT PRIMARY KEY,
  shop_id TEXT REFERENCES shops(shop_id),
  user_id TEXT REFERENCES users(user_id),
  role TEXT DEFAULT 'admin',
  UNIQUE(shop_id, user_id)
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
  product_id TEXT PRIMARY KEY,
  shop_id TEXT REFERENCES shops(shop_id),
  name TEXT NOT NULL,
  category TEXT,
  purchase_price REAL DEFAULT 0,
  selling_price REAL DEFAULT 0,
  stock INTEGER DEFAULT 0,
  image_url TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Customers table
CREATE TABLE IF NOT EXISTS customers (
  customer_id TEXT PRIMARY KEY,
  shop_id TEXT REFERENCES shops(shop_id),
  name TEXT NOT NULL,
  mobile TEXT,
  address TEXT,
  outstanding_balance REAL DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Bills (Invoices) table
CREATE TABLE IF NOT EXISTS bills (
  bill_id TEXT PRIMARY KEY,
  shop_id TEXT REFERENCES shops(shop_id),
  customer_id TEXT REFERENCES customers(customer_id),
  bill_number TEXT,
  subtotal REAL DEFAULT 0,
  discount REAL DEFAULT 0,
  grand_total REAL DEFAULT 0,
  payment_method TEXT,
  payment_status TEXT, -- 'paid', 'unpaid', 'partial'
  amount_paid REAL DEFAULT 0,
  invoice_url TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Bill Items table
CREATE TABLE IF NOT EXISTS bill_items (
  item_id TEXT PRIMARY KEY,
  bill_id TEXT REFERENCES bills(bill_id),
  product_id TEXT REFERENCES products(product_id),
  quantity INTEGER DEFAULT 1,
  price REAL DEFAULT 0,
  total REAL DEFAULT 0
);

-- Payments (Udhar tracking)
CREATE TABLE IF NOT EXISTS payments (
  payment_id TEXT PRIMARY KEY,
  shop_id TEXT REFERENCES shops(shop_id),
  customer_id TEXT REFERENCES customers(customer_id),
  bill_id TEXT REFERENCES bills(bill_id),
  amount REAL NOT NULL,
  payment_mode TEXT,
  payment_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- OTP tracking (expires in 30 seconds)
CREATE TABLE IF NOT EXISTS otps (
  id TEXT PRIMARY KEY,
  identifier TEXT NOT NULL, -- Mobile or Email
  otp_code TEXT NOT NULL,
  expires_at DATETIME NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Offline Sync Log
CREATE TABLE IF NOT EXISTS sync_logs (
  sync_id TEXT PRIMARY KEY,
  shop_id TEXT,
  table_name TEXT,
  record_id TEXT,
  action TEXT, -- 'INSERT', 'UPDATE', 'DELETE'
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
