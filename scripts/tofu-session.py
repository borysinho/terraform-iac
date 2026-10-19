#!/usr/bin/env python3
"""Ejecuta OpenTofu con credenciales temporales de AWS CLI, solo en memoria.

Uso: python3 scripts/tofu-session.py --aws-profile default [argumentos de tofu]
Necesario para backends de versiones de OpenTofu que no leen login_session.
"""
import argparse
import json
import os
import subprocess
import sys

parser = argparse.ArgumentParser(add_help=False)
parser.add_argument("--aws-profile", default=os.environ.get("AWS_PROFILE", "default"))
args, tofu_args = parser.parse_known_args()
if not tofu_args:
    sys.exit("Uso: tofu-session.py --aws-profile PERFIL [argumentos de tofu]")
result = subprocess.run(
    ["aws", "configure", "export-credentials", "--profile", args.aws_profile, "--format", "process"],
    capture_output=True, text=True,
)
if result.returncode:
    sys.stderr.write(result.stderr)
    sys.exit(result.returncode)
credentials = json.loads(result.stdout)
env = os.environ.copy()
env["AWS_ACCESS_KEY_ID"] = credentials["AccessKeyId"]
env["AWS_SECRET_ACCESS_KEY"] = credentials["SecretAccessKey"]
if credentials.get("SessionToken"):
    env["AWS_SESSION_TOKEN"] = credentials["SessionToken"]
else:
    env.pop("AWS_SESSION_TOKEN", None)
env.pop("AWS_PROFILE", None)
env.setdefault("AWS_REGION", "us-east-2")
env.setdefault("AWS_DEFAULT_REGION", "us-east-2")
sys.exit(subprocess.run(["tofu", *tofu_args], env=env).returncode)
