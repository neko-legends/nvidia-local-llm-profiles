import argparse
import os
import sys
import time
import urllib.request


def download(url: str, destination: str) -> None:
    os.makedirs(os.path.dirname(os.path.abspath(destination)), exist_ok=True)
    tmp = destination + ".part"
    existing = os.path.getsize(tmp) if os.path.exists(tmp) else 0

    request = urllib.request.Request(url)
    if existing:
        request.add_header("Range", f"bytes={existing}-")

    started = time.time()
    with urllib.request.urlopen(request, timeout=120) as response:
        status = getattr(response, "status", 200)
        if existing and status == 200:
            existing = 0
            open(tmp, "wb").close()

        total_header = response.headers.get("Content-Length")
        total_remaining = int(total_header) if total_header else 0
        total = existing + total_remaining if total_remaining else 0

        mode = "ab" if existing else "wb"
        done = existing
        last_report = 0.0
        with open(tmp, mode) as out:
            while True:
                chunk = response.read(1024 * 1024 * 8)
                if not chunk:
                    break
                out.write(chunk)
                done += len(chunk)
                now = time.time()
                if now - last_report >= 10:
                    elapsed = max(0.001, now - started)
                    mib = done / 1024 / 1024
                    speed = (done - existing) / 1024 / 1024 / elapsed
                    if total:
                        pct = done * 100 / total
                        print(f"{mib:.1f} MiB / {total / 1024 / 1024:.1f} MiB ({pct:.1f}%), {speed:.1f} MiB/s", flush=True)
                    else:
                        print(f"{mib:.1f} MiB downloaded, {speed:.1f} MiB/s", flush=True)
                    last_report = now

    os.replace(tmp, destination)
    print(f"Downloaded: {destination}", flush=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True)
    parser.add_argument("--filename", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    url = f"https://huggingface.co/{args.repo}/resolve/main/{args.filename}"
    try:
        download(url, args.out)
        return 0
    except Exception as exc:
        print(f"download failed: {type(exc).__name__}: {exc}", file=sys.stderr, flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
