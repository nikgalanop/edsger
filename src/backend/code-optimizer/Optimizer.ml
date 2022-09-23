open Llvm
open Llvm_scalar_opts

let optimize m = 
  let fpm = PassManager.create () in 
  let opts = [add_memory_to_register_promotion;
    add_instruction_combination; add_reassociation;
    add_aggressive_dce; add_cfg_simplification; 
    add_gvn] in
  List.iter (( |> ) fpm) opts;
  ignore @@ PassManager.run_module m fpm