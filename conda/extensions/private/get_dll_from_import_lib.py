#!/usr/bin/env python3
import sys
import struct


def read_cstr(data, offset):
    end = data.find(b"\x00", offset)
    if end == -1:
        return None, len(data)
    return data[offset:end].decode("ascii", errors="ignore"), end + 1


def parse_lib(path):
    with open(path, "rb") as f:
        data = f.read()

    if not data.startswith(b"!<arch>\n"):
        sys.exit("Not a valid COFF archive (.lib)")

    pos = 8  # skip global header
    dlls = set()

    while pos + 60 <= len(data):
        hdr = data[pos : pos + 60]
        name = hdr[:16].rstrip()
        try:
            size = int(hdr[48:58].decode("ascii").strip())
        except ValueError:
            break
        if hdr[58:60] != b"`\n":
            break
        pos_data = pos + 60
        pos_next = pos_data + size
        if pos_next > len(data):
            break
        member = data[pos_data:pos_next]

        # Short-import header check (Sig1=0, Sig2=0xFFFF)
        if len(member) >= 20:
            sig1, sig2 = struct.unpack_from("<HH", member, 0)
            if sig1 == 0 and sig2 == 0xFFFF:
                _, off = read_cstr(member, 20)  # import name (ignored)
                dll_name, _ = read_cstr(member, off)
                if dll_name:
                    return dll_name

        # 2-byte alignment
        pos = pos_next + (pos_next % 2)

    return None


def main():
    if len(sys.argv) != 2:
        sys.exit(f"Usage: {sys.argv[0]} <library.lib>")
    dll = parse_lib(sys.argv[1])
    if dll:
        print(dll)


if __name__ == "__main__":
    main()
