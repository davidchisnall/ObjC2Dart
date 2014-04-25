# Packages symlink
file(COPY Packages DESTINATION .)

# Compile
objc2dart(functions)
objc2dart(type-definitions)
objc2dart(comma-separated-expressions)
objc2dart(type-functionality)

# Test
add_diff_test(functions)
add_diff_test(type-definitions)
add_dart_test(comma-separated-expressions)
add_dart_test(type-functionality)
