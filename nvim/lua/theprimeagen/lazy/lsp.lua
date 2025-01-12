return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "j-hui/fidget.nvim",
        "rafamadriz/friendly-snippets",
        "nvim-treesitter/nvim-treesitter",
    },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        -- Configuração de capacidades do LSP com integração ao CMP
        local cmp = require("cmp")
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities()
        )

        -- Configuração do Treesitter
        require("nvim-treesitter.configs").setup({
            ensure_installed = {
                "lua",
                "rust",
                "go",
                "python",
                "bash",
                "html",
                "css",
                "javascript",
                "typescript",
                "hcl", -- Para Terraform
                "json",
                "yaml",
                "markdown",
            },
            sync_install = true,
            auto_install = true,
            ignore_install = {}, -- Deixe vazio se nenhuma linguagem deve ser ignorada
            highlight = {
                enable = true, -- Ativar destaque de sintaxe
            },
            indent = {
                enable = true, -- Ativar indentação automática
            },
            modules = {}, -- Configuração personalizada de módulos, se necessário
        })

        -- Configuração do LuaSnip e carregamento de snippets
        require("luasnip.loaders.from_vscode").lazy_load()

        -- Configuração do Fidget para exibir progresso do LSP
        require("fidget").setup({})

        -- Configuração do Mason e Mason-LSPConfig
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = {
                "bashls",         -- Bash
                "cssls",          -- CSS
                "eslint",         -- JavaScript/TypeScript linting
                "gopls",          -- Go
                "html",           -- HTML
                "jsonls",         -- JSON
                "lua_ls",         -- Lua
                "pylsp",          -- Python
                "rust_analyzer",  -- Rust
                "terraformls",    -- Terraform
                "tflint",         -- Terraform linting
            },
            automatic_installation = true,
            handlers = {
                function(server_name)
                    require("lspconfig")[server_name].setup({
                        capabilities = capabilities,
                    })
                end,
                -- Configuração personalizada para HTML
                ["html"] = function()
                    require("lspconfig").html.setup({
                        capabilities = capabilities,
                        filetypes = { "html", "templ" },
                        init_options = {
                            configurationSection = { "html", "css", "javascript" },
                            embeddedLanguages = {
                                css = true,
                                javascript = true,
                            },
                            provideFormatter = true,
                        },
                        settings = {
                            html = {
                                format = { enable = true },
                                hover = {
                                    documentation = true,
                                    references = true,
                                },
                            },
                        },
                    })
                end,
                -- Configuração personalizada para Lua
                ["lua_ls"] = function()
                    require("lspconfig").lua_ls.setup({
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                runtime = { version = "Lua 5.1" },
                                diagnostics = {
                                    globals = { "vim", "bit", "it", "describe", "before_each", "after_each" },
                                },
                                workspace = {
                                    library = vim.api.nvim_get_runtime_file("", true),
                                    checkThirdParty = false,
                                },
                                telemetry = { enable = false },
                            },
                        },
                    })
                end,
            },
        })

        -- Configuração do CMP (autocompletar)
        local cmp_select = { behavior = cmp.SelectBehavior.Select }
        cmp.setup({
            snippet = {
                expand = function(args)
                    require("luasnip").lsp_expand(args.body)
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
                ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
                ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<Tab>"] = cmp.mapping(function(fallback)
                    local luasnip = require("luasnip")
                    if cmp.visible() then
                        cmp.select_next_item()
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    else
                        fallback()
                    end
                end, { "i", "s" }),
            }),
            sources = cmp.config.sources({
                { name = "nvim_lsp" },
                { name = "luasnip" },
            }, {
                { name = "buffer" },
                { name = "path" },
            }),
        })

        -- Configuração de diagnósticos do Neovim
        vim.diagnostic.config({
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = true,
                header = "",
                prefix = "",
            },
        })
    end,
}

