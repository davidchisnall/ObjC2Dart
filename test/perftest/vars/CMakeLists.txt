# Packages symlink
file(COPY Packages DESTINATION .)

# Compile
objc2dart(qsort)
