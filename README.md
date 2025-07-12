# Threadly - Premium C2C Fashion Marketplace

A modern peer-to-peer fashion marketplace built with SvelteKit, Tailwind CSS, and Supabase. Threadly creates a trusted environment where fashion enthusiasts can buy, sell, and discover pre-owned designer items and quality fashion pieces.

## 🚀 Tech Stack

- **Framework**: SvelteKit 2.22.5 with Svelte 5
- **Styling**: Tailwind CSS v4 (alpha) + shadcn-svelte
- **Database**: Supabase (PostgreSQL)
- **Type Safety**: TypeScript with strict mode
- **Payment**: Stripe Connect
- **Storage**: Cloudflare R2
- **Search**: Meilisearch
- **Email**: Resend

## 📋 Prerequisites

- Node.js 18+ and pnpm
- Supabase account
- Stripe account
- Cloudflare account (for R2 storage)
- Resend account (for emails)

## 🛠️ Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd threadly-svelte
   ```

2. **Install dependencies**
   ```bash
   pnpm install
   ```

3. **Environment setup**
   ```bash
   cp .env.example .env.local
   ```
   Fill in your environment variables in `.env.local`

4. **Database setup**
   - Create a new Supabase project
   - Run migrations (coming soon)
   - Configure Row Level Security

5. **Start development server**
   ```bash
   pnpm dev
   ```
   The app will be available at http://localhost:5180

## 📁 Project Structure

```
src/
├── lib/
│   ├── components/     # Reusable components
│   │   ├── ui/        # shadcn-svelte components
│   │   ├── layout/    # Layout components
│   │   ├── listings/  # Listing-related components
│   │   └── user/      # User-related components
│   ├── stores/        # Svelte stores
│   ├── types/         # TypeScript types
│   ├── utils/         # Utility functions
│   ├── server/        # Server-side utilities
│   ├── schemas/       # Zod schemas
│   └── hooks/         # Custom hooks
├── routes/
│   ├── (auth)/        # Authentication routes
│   ├── (app)/         # Main app routes
│   └── api/           # API endpoints
└── app.css            # Global styles
```

## 🧪 Development

### Code Quality
- **ESLint**: `pnpm lint`
- **Prettier**: `pnpm format`
- **Type Check**: `pnpm check`

### Testing
```bash
pnpm test        # Run tests
pnpm test:unit   # Unit tests only
pnpm test:e2e    # E2E tests only
```

### Git Workflow
1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes and commit
3. Push branch and create PR
4. Ensure all checks pass

## 🚀 Deployment

### Production Build
```bash
pnpm build
pnpm preview  # Preview production build
```

### Deployment Platforms
- **Recommended**: Vercel (automatic deployments)
- **Alternative**: Any Node.js hosting platform

## 📚 Key Features

- **User Authentication**: Secure login/registration with Supabase Auth
- **Listing Management**: Create, edit, and manage fashion listings
- **Real-time Messaging**: Chat between buyers and sellers
- **Secure Payments**: Stripe Connect for secure transactions
- **Image Upload**: Cloudflare R2 for fast image delivery
- **Search & Discovery**: Meilisearch-powered search
- **Mobile-First**: Responsive design for all devices

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is proprietary and confidential.

## 🆘 Support

For issues and questions:
- Create an issue in the repository
- Contact the development team

---

Built with ❤️ using SvelteKit and Tailwind CSS