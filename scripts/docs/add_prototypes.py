#!/usr/bin/env python
from __future__ import print_function

import re

# add the namespace qualifiers to classes, just in case they change
def add_namespace_to_classes(lines):
    pass

# add prototype to natural doc documented classes
def add_prototypes(lines):
    cur_class = None
    need_proto = False
    namespace = None
    will_indent = 0
    will_replace = None

    for i, line in enumerate(lines):
        if line.strip().startswith("namespace "):
            namespace = line.strip().split(" ")[1].strip(":")

        if line.find("//") == -1:
            if need_proto:
                if will_replace is not None:
                    tokens = line.lstrip().split()
                    n_tokens = []
                    for tok in tokens:
                        tok = re.sub("<.*>", "", tok)
                        if tok.find("::") != -1 or not namespace or \
                        tok in ["public", "private", "class", "struct"]:
                            n_tokens.append(tok)
                        elif tok == ":":
                            n_tokens.append("extends")
                        else:
                            n_tokens.append("%s::%s" % (namespace, tok))

                    lines[will_replace] = (will_indent * " ") + "// " + " ".join(n_tokens) + "\n"
                    will_replace = None
            continue

        line = line.lstrip("/")
        if line.lower().startswith("class:"):
            tokens = line.split(":")[1]
            cur_class = tokens[1]

        if line.lower().find("--- prototype") != -1:
            need_proto = True
            will_replace = i+1
            will_indent = len(lines[i+1]) - len(lines[i+1].lstrip())
    return lines


if __name__ == "__main__":
    import sys
    lines = sys.stdin.readlines()
    print("".join(add_prototypes(lines)).rstrip())
