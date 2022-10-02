open Llvm
open Llvm_scalar_opts
open Llvm_passmgr_builder

let initialize_lvl2 m = 
  let pm = create () in 
  set_opt_level 2 pm;
  let mpm = PassManager.create () in 
  populate_module_pass_manager mpm pm;
  mpm 

let custom_initialize m = 
  let mpm = PassManager.create () in  
  let opts = [add_memory_to_register_promotion;
    add_instruction_combination; add_reassociation;
    add_cfg_simplification; add_gvn;
    add_aggressive_dce] in
  List.iter (( |> ) mpm) opts;
  mpm 

let optimize m = 
  let mpm = custom_initialize m in 
  ignore @@ PassManager.run_module m mpm;
  match Llvm_analysis.verify_module m with 
  | None -> ()
  | Some s -> failwith "Unsafe Optimizations"