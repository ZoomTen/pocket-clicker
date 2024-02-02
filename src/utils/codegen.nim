import std/macros
export macros

{.experimental: "codeReordering".}

# i can't yet find a way to make bank numbers a Nim pragma
# so {.emit: "#pragma bank N".} will have to do for now.

macro homeProc*(node: untyped): untyped = codeGenMacro("NONBANKED")
macro bankedProc*(node: untyped): untyped = codeGenMacro("BANKED")
macro oldCall*(node: untyped): untyped = codeGenMacro("__sdcccall(0)")
macro newCall*(node: untyped): untyped = codeGenMacro("__sdcccall(1)")

template codeGenMacro (appendString: string) {.dirty.} =
    ## thanks @rockcavera!
    result = newStmtList()
    if node.kind not_in [nnkProcDef, nnkFuncDef]:
        result.add(node)
        return
    # silly: if a codegen pragma already exists, add NONBANKED to it
    for child in node:
        if child.kind == nnkPragma:
            for pragma in child:
                if pragma.kind == nnkExprColonExpr:
                    if pragma[0] == newIdentNode("codegenDecl"):
                        pragma[1] = newLit(pragma[1].strval & " " & appendString)
                        result.add(node)
                        return
    # otherwise, add the pragma
    node.addPragma(
        nnkExprColonExpr.newTree(
            newIdentNode("codegenDecl"),
            newLit("$# $#$# " & appendString)
        )
    )
    result.add(node)

