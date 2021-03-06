
let config_mk = "config.mk"

(* Configure script *)
open Cmdliner

let info =
  let doc = "Configures a package" in
  Term.info "configure" ~version:"0.1" ~doc 

let output_file filename lines =
  let oc = open_out filename in
  let lines = List.map (fun line -> line ^ "\n") lines in
  List.iter (output_string oc) lines;
  close_out oc

let find_header verbose name =
  let c_program = [
    Printf.sprintf "#include <%s>" name;
    "int main(int argc, const char *argv){";
    "return 0;";
    "}";
  ] in
  let c_file = Filename.temp_file "looking_for_header" ".c" in
  let o_file = c_file ^ ".o" in
  output_file c_file c_program;
  let found = Sys.command (Printf.sprintf "cc -c %s -o %s %s" c_file o_file (if verbose then "" else "2>/dev/null")) = 0 in
  if Sys.file_exists c_file then Sys.remove c_file;
  if Sys.file_exists o_file then Sys.remove o_file;
  Printf.printf "Looking for %s: %s\n" name (if found then "ok" else "missing");
  found

let configure verbose =
  let xenctrl = find_header verbose "xenctrl.h" in
  (* Write config.mk *)
  let lines = 
    [ "# Warning - this file is autogenerated by the configure script";
      "# Do not edit";
      Printf.sprintf "ENABLE_XENCTRL=--%s-xenctrl" (if xenctrl then "enable" else "disable");
    ] in
  output_file config_mk lines

let arg =
  let doc = "enable verbose printing" in
  Arg.(value & flag & info ["verbose"; "v"] ~doc)

let configure_t = Term.(pure configure $ arg)

let () = 
  match 
    Term.eval (configure_t, info) 
  with
  | `Error _ -> exit 1 
  | _ -> exit 0
