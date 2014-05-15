# Packages symlink
file(COPY Packages DESTINATION .)

# Compile
objc2dart(stdarg)

# Test
add_dart_test(stdarg)
