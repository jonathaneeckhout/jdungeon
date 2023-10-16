FROM ubuntu:22.04

USER root

ARG GODOT_VERSION="4.1.2"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    git-lfs \
    unzip \
    wget \
    zip \
    adb \
    openjdk-11-jdk-headless \
    rsync \
    dotnet-sdk-6.0 \
    && rm -rf /var/lib/apt/lists/*



RUN wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_mono_linux_x86_64.zip \
    && wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_mono_export_templates.tpz \
    && mkdir ~/.cache \
    && mkdir -p ~/.config/godot \
    && mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable.mono \
    && unzip Godot_v${GODOT_VERSION}-stable_mono_linux_x86_64.zip \
    && ln Godot_v${GODOT_VERSION}-stable_mono_linux_x86_64/Godot_v${GODOT_VERSION}-stable_mono_linux.x86_64 /usr/bin/godot \
    && unzip Godot_v${GODOT_VERSION}-stable_mono_export_templates.tpz \
    && cp -r templates/* ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable.mono/ \
    && rm -rf Godot_v${GODOT_VERSION}-stable_mono_linux_x86_64.zip  Godot_v${GODOT_VERSION}-stable_mono_export_templates.tpz templates
