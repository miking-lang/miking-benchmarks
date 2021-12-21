// Compile on Ubuntu 20.04 using: g++ -std=c++17 toml-to-json.cpp -o toml-to-json


#include <iostream>
#include "toml.hpp"

int main(int argc, char** argv) {
  toml::table tbl;
  try {
    tbl = toml::parse_file(argv[1]);
  } catch (const toml::parse_error& err) {
    std::cerr << "Parsing failed:\n" << err << "\n";
    return 1;
  }

  std::cout << toml::json_formatter{ tbl } << "\n\n";
  return 0;
}
