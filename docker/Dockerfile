# ── Stage 1: package .love file ───────────────────────────────────────────────
FROM alpine:3.19 AS packager
WORKDIR /build
RUN apk add --no-cache zip
COPY . .
# Zip Lua source + assets into game.love (excluding dev/build dirs)
RUN zip -r game.love . \
      -x "docker/*" \
      -x "docs/*" \
      -x ".git/*" \
      -x "tests/*" \
      -x "*.sh" \
      -x ".gitignore" \
      -x "Library/*" \
      -x "Packages/*" \
      -x "ProjectSettings/*" \
      -x "UserSettings/*" \
      -x "Logs/*" \
      -x "*.py"

# ── Stage 2: nginx serve ──────────────────────────────────────────────────────
FROM nginx:1.25-alpine AS runtime
WORKDIR /usr/share/nginx/html
# Remove default nginx content
RUN rm -f /etc/nginx/conf.d/default.conf index.html

# love.js pre-built binaries (committed to repo at docker/lovejs/)
COPY docker/lovejs/ ./lovejs/

# Packaged game
COPY --from=packager /build/game.love ./game.love

# Shell + config
COPY docker/index.html ./index.html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
