from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from tqdm import tqdm


def add_gguf_to_path(llama_cpp_src: Path) -> None:
    gguf_py = llama_cpp_src / "gguf-py"
    if not gguf_py.exists():
        raise FileNotFoundError(f"Could not find gguf-py under {llama_cpp_src}")
    sys.path.insert(0, str(gguf_py))


def import_gguf(llama_cpp_src: Path | None):
    try:
        import gguf

        return gguf
    except ModuleNotFoundError:
        env_src = os.environ.get("LLAMA_CPP_SRC")
        resolved_src = llama_cpp_src or (Path(env_src) if env_src else None)
        if resolved_src is None:
            raise SystemExit(
                "Could not import gguf. Install gguf-py, pass --llama-cpp-src, "
                "or set LLAMA_CPP_SRC to a llama.cpp source checkout."
            )

    add_gguf_to_path(resolved_src)
    import gguf

    return gguf


def field_value(field):
    return field.contents()


def add_field(writer, gguf, key: str, value, value_type, sub_type=None) -> None:
    writer.add_key_value(key, value, value_type, sub_type=sub_type)


def copy_metadata(base_reader, writer, gguf) -> None:
    for field in base_reader.fields.values():
        if field.name.startswith("GGUF."):
            continue
        if field.name == gguf.Keys.General.ARCHITECTURE:
            continue

        value_type = field.types[0]
        sub_type = field.types[-1] if value_type == gguf.GGUFValueType.ARRAY else None
        value = field_value(field)

        if field.name == "general.name":
            value = "Ornith 1.0 35B AEON Ultimate Uncensored NVFP4 MTP"
        elif field.name == "general.finetune":
            value = "AEON-Ultimate-Uncensored-NVFP4-MTP"
        elif field.name == "qwen35moe.block_count":
            value = 41

        add_field(writer, gguf, field.name, value, value_type, sub_type=sub_type)

    if base_reader.get_field("qwen35moe.nextn_predict_layers") is None:
        writer.add_uint32("qwen35moe.nextn_predict_layers", 1)

    writer.add_string(
        "general.description",
        "AEON Ultimate Uncensored NVFP4 GGUF trunk with a grafted compatible MTP block for llama.cpp draft-mtp serving.",
    )
    writer.add_string(
        "general.url",
        "https://huggingface.co/AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4",
    )


def tensor_map(reader) -> dict[str, object]:
    return {tensor.name: tensor for tensor in reader.tensors}


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Create an AEON-trunk Ornith NVFP4 GGUF with a grafted MTP block."
    )
    parser.add_argument(
        "--llama-cpp-src",
        type=Path,
        default=None,
        help="Optional llama.cpp source checkout containing gguf-py. Can also be set with LLAMA_CPP_SRC.",
    )
    parser.add_argument("--base-gguf", type=Path, required=True)
    parser.add_argument("--donor-mtp-gguf", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    gguf = import_gguf(args.llama_cpp_src)

    if args.out.exists() and not args.force:
        raise FileExistsError(f"{args.out} exists; pass --force to overwrite")
    args.out.parent.mkdir(parents=True, exist_ok=True)

    base = gguf.GGUFReader(args.base_gguf, "r")
    donor = gguf.GGUFReader(args.donor_mtp_gguf, "r")

    arch = field_value(base.get_field(gguf.Keys.General.ARCHITECTURE))
    writer = gguf.GGUFWriter(args.out, arch=arch, endianess=base.endianess)
    writer.data_alignment = base.alignment

    copy_metadata(base, writer, gguf)

    donor_tensors = tensor_map(donor)
    mtp_tensors = [tensor for tensor in donor.tensors if tensor.name.startswith("blk.40.")]
    required = {
        "blk.40.attn_norm.weight",
        "blk.40.nextn.eh_proj.weight",
        "blk.40.nextn.enorm.weight",
        "blk.40.nextn.hnorm.weight",
        "blk.40.nextn.shared_head_norm.weight",
    }
    missing = sorted(required - set(donor_tensors))
    if missing:
        raise ValueError(f"Donor GGUF is missing required MTP tensors: {missing}")

    all_tensors = list(base.tensors) + mtp_tensors
    for tensor in all_tensors:
        writer.add_tensor_info(
            tensor.name,
            tensor.data.shape,
            tensor.data.dtype,
            tensor.data.nbytes,
            raw_dtype=tensor.tensor_type,
        )

    total_bytes = sum(tensor.n_bytes for tensor in all_tensors)
    bar = tqdm(desc="Writing AEON MTP GGUF", total=total_bytes, unit="byte", unit_scale=True)

    writer.write_header_to_file()
    writer.write_kv_data_to_file()
    writer.write_ti_data_to_file()

    for tensor in all_tensors:
        source_endianess = base.endianess if not tensor.name.startswith("blk.40.") else donor.endianess
        writer.write_tensor_data(tensor.data, tensor_endianess=source_endianess)
        bar.update(tensor.n_bytes)

    writer.close()
    bar.close()

    print(f"Wrote {args.out}")
    print(f"Base tensors: {len(base.tensors)}")
    print(f"MTP tensors grafted: {len(mtp_tensors)}")
    print(f"Total tensors: {len(all_tensors)}")


if __name__ == "__main__":
    main()
