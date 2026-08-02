export type Bindings = {
  DB: D1Database;
  JWT_SECRET: string;
};

export type JWTPayload = {
  userId: string;
  shopId?: string;
  role?: string;
  exp: number; // Expiration time
};
