FROM dart:3.10.0
WORKDIR /app
COPY pubspec.yaml .
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o bin/server
FROM debian:bookworm-slim
WORKDIR /app
COPY --from=0 /app/bin/server /app/bin/server
EXPOSE 8080
USER 65532:65532
ENTRYPOINT ["/app/bin/server"]
