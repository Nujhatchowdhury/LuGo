FROM dart:stable

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

COPY pubspec.* ./
RUN dart pub get

COPY . .

EXPOSE 8080

CMD ["dart", "run", "bin/lugo_backend.dart"]
