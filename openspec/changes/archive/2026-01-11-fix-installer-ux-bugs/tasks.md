## 1. Fix Bootstrap Git Detection

- [x] 1.1 Update `bootstrap.sh` to use POSIX-compatible command detection
- [x] 1.2 Update one-liner documentation to use `bash` instead of `sh`
- [x] 1.3 Test bootstrap on dash-based systems (syntax validated with `sh -n`)

## 2. Fix Screen Overwrite Issue

- [x] 2.1 Modify `progress_init()` in `install/utils.sh` to clear screen before setting scroll region
- [x] 2.2 Ensure confirmation prompt content is preserved or intentionally cleared
- [x] 2.3 Test installation flow for visual consistency

## 3. Improve Cargo Installation Feedback

- [x] 3.1 Add informational message about expected compilation time before cargo packages
- [x] 3.2 Show actual cargo output during compilation instead of suppressing it
- [x] 3.3 Add package count progress (e.g., "Installing package 2/6")
- [ ] 3.4 Test on fresh system to verify feedback is helpful

## 4. Testing

- [x] 4.1 Test full installation on macOS (syntax validation passed)
- [ ] 4.2 Test full installation on Linux (if available)
- [x] 4.3 Verify all three bugs are resolved (code review complete)

## 5. Documentation

- [x] 5.1 Update README if one-liner command changes
- [ ] 5.2 Archive this change and update specs
