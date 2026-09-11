# -----
# Stage 1: Build
# -----
FROM ghcr.io/pnpm/pnpm:11 AS build

WORKDIR /workbench
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm ci

COPY . .
RUN pnpm run build

# -----
# Stage 2: Production
# -----
FROM gcr.io/distroless/nodejs22-debian13 AS production
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /workbench/build ./dist
CMD [ "./dist/index.mjs" ]
