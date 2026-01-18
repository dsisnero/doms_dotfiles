# Test Deployment Instructions

## Quick Test Commands

### 1. **Backup Current Configuration**

```bash
# Backup your current nvim config
mv ~/.config/nvim ~/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)

# Optional: Clean Neovim data directories for fresh install
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim
```

### 2. **Test Manual Deployment**

```bash
# Set variables
CONFIG_HOME="$HOME/.config"
DOTFILES_DIR="/Users/dominic/repos/github.com/dsisnero/doms_dotfiles"
TEMPLATE_DIR="$DOTFILES_DIR/config/nvim/astronvim_template"

# Create directory
mkdir -p "$CONFIG_HOME/nvim"

# Copy configuration
cp -r "$TEMPLATE_DIR"/* "$CONFIG_HOME/nvim/"

# Clean utility files
cd "$CONFIG_HOME/nvim"
rm -f install.sh test_config.lua deploy_with_itamae.rb NEXT_STEPS.md

# Test Neovim
nvim
```

### 3. **Test Itamae Deployment**

```bash
cd /Users/dominic/repos/github.com/dsisnero/doms_dotfiles

# Run the updated cookbook
itamae local cookbooks/neovim/default.rb

# Test Neovim
nvim
```

## What to Test in Neovim

After deployment, open Neovim and test:

### **Basic Functionality**

```vim
:checkhealth          # Check system health
:Lazy                 # Open lazy.nvim interface
:Mason                # Open Mason package manager
:TSUpdate             # Update treesitter parsers
```

### **Plugin Verification**

1. **Lazy.nvim**: Should show all plugins loading
2. **Telescope**: Press `<leader>ff` to find files
3. **LSP**: Open a code file, check for LSP features
4. **Treesitter**: Syntax highlighting should work
5. **UI**: Colorscheme and statusline should appear

### **Key Mappings Test**

- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>fb` - Find buffers
- `gd` - Go to definition
- `K` - Hover documentation
- `<leader>ca` - Code actions

## Troubleshooting

### **If Neovim Doesn't Start**

```bash
# Check for errors
nvim --headless +"Lazy! sync" +qa

# Check logs
nvim --headless +"messages" +qa
```

### **If Plugins Don't Load**

```bash
# Clean and reinstall
rm -rf ~/.local/share/nvim/lazy
nvim  # First start will reinstall plugins
```

### **If Configuration Has Errors**

```bash
# Check Lua syntax
cd ~/.config/nvim
lua -c "dofile('init.lua')"
```

## Rollback Instructions

If something goes wrong:

```bash
# Restore backup
rm -rf ~/.config/nvim
mv ~/.config/nvim.backup.* ~/.config/nvim

# Or use the old method temporarily
cd ~/repos/github.com/dsisnero/astronvim_config
ln -sf $(pwd) ~/.config/nvim
```

## Success Indicators

✅ **Successful deployment when:**

- Neovim starts without errors
- Lazy.nvim shows plugins loading
- All key mappings work
- LSP features are available
- UI looks correct (colorscheme, icons)

## Next After Testing

Once testing is successful:

1. **Commit the changes** to your dotfiles repository
2. **Update all your machines** using itamae
3. **Delete the old repository** if no longer needed:

   ```bash
   rm -rf ~/repos/github.com/dsisnero/astronvim_config
   ```

## Support

If you encounter issues:

1. Check `:messages` in Neovim for errors
2. Review the AstroNvim documentation
3. Check the configuration files for syntax errors
4. Try a clean installation (remove Neovim data directories)