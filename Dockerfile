# -----
# Stage 1: Build
# -----
FROM ghcr.io/pnpm/pnpm:11 AS build

WORKDIR /workbench
COPY package.json pnpm-lock.yaml ./
# Didn't use `pnpm ci`. Instead we want to skip the `prepare` script since it needs vite.config.ts, which is copied later.
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile --ignore-scripts

COPY . .
RUN pnpm run prepare && pnpm run build

# -----
# Stage 2: Production
# -----
FROM gcr.io/distroless/nodejs22-debian13 AS production
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /workbench/build ./dist
CMD [ "dist/index.js" ]
