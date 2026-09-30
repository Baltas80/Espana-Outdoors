from __future__ import annotations

from pathlib import Path
import os

VERSION = os.environ.get("AGUS_MAPS_VERSION", "0.1.18")
package_root = Path.home() / ".pub-cache" / "hosted" / "pub.dev" / f"agus_maps_flutter-{VERSION}"
source = package_root / "src" / "agus_maps_flutter.cpp"

if not source.is_file():
    raise SystemExit(f"Agus Maps native source not found: {source}")

text = source.read_text(encoding="utf-8")
original = text

old_globals = '''static std::unique_ptr<Framework> g_framework;\nstatic drape_ptr<dp::ThreadSafeFactory> g_factory;\nstatic std::string g_resourcePath;'''
new_globals = '''static std::unique_ptr<Framework> g_framework;\nstatic drape_ptr<dp::ThreadSafeFactory> g_factory;\nstatic agus::AgusOGLContextFactory* g_oglFactory = nullptr;\nstatic std::string g_resourcePath;'''
if old_globals not in text:
    raise SystemExit("Unexpected Agus Maps source: global factory block not found")
text = text.replace(old_globals, new_globals, 1)

old_factory = '''    auto oglFactory = new agus::AgusOGLContextFactory(window);\n    if (!oglFactory->IsValid()) {\n        __android_log_print(ANDROID_LOG_ERROR, "AgusMapsFlutterNative", "nativeSetSurface: Invalid OGL context");\n        delete oglFactory;\n        return;\n    }'''
new_factory = '''    auto oglFactory = new agus::AgusOGLContextFactory(window);\n    if (!oglFactory->IsValid()) {\n        __android_log_print(ANDROID_LOG_ERROR, "AgusMapsFlutterNative", "nativeSetSurface: Invalid OGL context");\n        delete oglFactory;\n        return;\n    }'''
if old_factory not in text:
    raise SystemExit("Unexpected Agus Maps source: factory creation block not found")

old_wrap = '''    // Wrap our context factory in ThreadSafeFactory for thread-safe context creation\n    g_factory = make_unique_dp<dp::ThreadSafeFactory>(oglFactory);'''
new_wrap = '''    // Keep the concrete factory so Android can replace the EGL window surface\n    // when Flutter destroys/recreates the SurfaceProducer surface.\n    g_oglFactory = oglFactory;\n\n    // Wrap our context factory in ThreadSafeFactory for thread-safe context creation\n    g_factory = make_unique_dp<dp::ThreadSafeFactory>(oglFactory);'''
if old_wrap not in text:
    raise SystemExit("Unexpected Agus Maps source: ThreadSafeFactory block not found")
text = text.replace(old_wrap, new_wrap, 1)

old_changed = '''    ANativeWindow* window = ANativeWindow_fromSurface(env, surface);\n    \n    g_surfaceWidth = width;\n    g_surfaceHeight = height;\n    g_density = density;\n    \n    if (g_factory && g_framework) {\n        // Re-enable rendering with new surface\n        auto* rawFactory = static_cast<dp::ThreadSafeFactory*>(g_factory.get());\n        if (rawFactory) {\n            // Get the underlying factory and reset surface\n            // Note: This is a simplified approach - may need more work for proper surface recreation\n            g_framework->SetRenderingEnabled(make_ref(g_factory));\n            g_framework->OnSize(width, height);\n        }\n    }\n    \n    if (window) ANativeWindow_release(window);'''
new_changed = '''    ANativeWindow* window = ANativeWindow_fromSurface(env, surface);\n    \n    g_surfaceWidth = width;\n    g_surfaceHeight = height;\n    g_density = density;\n    \n    if (!window) {\n        __android_log_print(ANDROID_LOG_ERROR, "AgusMapsFlutterNative",\n            "nativeOnSurfaceChanged: ANativeWindow_fromSurface returned null");\n        return;\n    }\n\n    if (g_factory && g_framework && g_oglFactory) {\n        // The old implementation kept the ANativeWindow/EGLSurface from the\n        // previous Flutter SurfaceProducer. That leaves DrapeEngine with a\n        // stale native window after a surface recreation and can cause SIGSEGV\n        // or black frames. Reset the old EGL surface, install the new window,\n        // then re-enable rendering on the existing Framework.\n        g_oglFactory->ResetSurface();\n        g_oglFactory->SetSurface(window);\n        g_oglFactory->UpdateSurfaceSize(width, height);\n        \n        if (!g_oglFactory->IsValid()) {\n            __android_log_print(ANDROID_LOG_ERROR, "AgusMapsFlutterNative",\n                "nativeOnSurfaceChanged: recreated OGL surface is invalid");\n            return;\n        }\n\n        g_framework->SetRenderingEnabled(make_ref(g_factory));\n        g_framework->OnSize(width, height);\n        g_framework->InvalidateRendering();\n        g_framework->InvalidateRect(g_framework->GetCurrentViewport());\n        g_framework->MakeFrameActive();\n        return;\n    }\n\n    ANativeWindow_release(window);'''
if old_changed not in text:
    raise SystemExit("Unexpected Agus Maps source: surface-changed block not found")
text = text.replace(old_changed, new_changed, 1)

old_destroy = '''    if (g_framework) {\n        g_framework->SetRenderingDisabled(true /* destroySurface */);\n    }'''
new_destroy = '''    if (g_framework) {\n        g_framework->SetRenderingDisabled(true /* destroySurface */);\n    }\n\n    if (g_oglFactory) {\n        // Release the old EGL window surface and ANativeWindow reference.\n        // The Framework remains alive and will reuse this factory when the\n        // Flutter SurfaceProducer provides the replacement surface.\n        g_oglFactory->ResetSurface();\n    }'''
if old_destroy not in text:
    raise SystemExit("Unexpected Agus Maps source: surface-destroyed block not found")
text = text.replace(old_destroy, new_destroy, 1)

if text == original:
    raise SystemExit("Agus Maps lifecycle patch made no changes")

source.write_text(text, encoding="utf-8")
print(f"Patched Agus Maps {VERSION}: {source}")
