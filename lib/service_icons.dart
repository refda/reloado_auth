const Map<String, String> _domainToSlug = {
  // Google
  'google.com': 'google',
  'accounts.google.com': 'google',
  'gmail.com': 'gmail',
  'youtube.com': 'youtube',
  // Apple
  'apple.com': 'apple',
  'appleid.apple.com': 'apple',
  'icloud.com': 'icloud',
  // Microsoft
  'microsoft.com': 'microsoft',
  'live.com': 'microsoft',
  'microsoftonline.com': 'microsoft',
  'outlook.com': 'microsoftoutlook',
  'hotmail.com': 'microsoftoutlook',
  'azure.com': 'microsoftazure',
  'azure.microsoft.com': 'microsoftazure',
  'xbox.com': 'xbox',
  // Meta
  'facebook.com': 'facebook',
  'meta.com': 'meta',
  'instagram.com': 'instagram',
  'whatsapp.com': 'whatsapp',
  // Twitter / X
  'twitter.com': 'x',
  'x.com': 'x',
  // Developer
  'github.com': 'github',
  'gitlab.com': 'gitlab',
  'bitbucket.org': 'bitbucket',
  'npmjs.com': 'npm',
  'docker.com': 'docker',
  'hub.docker.com': 'docker',
  'heroku.com': 'heroku',
  'digitalocean.com': 'digitalocean',
  'cloudflare.com': 'cloudflare',
  'vercel.com': 'vercel',
  'netlify.com': 'netlify',
  'atlassian.com': 'atlassian',
  'jira.atlassian.com': 'jirasoftware',
  'confluence.atlassian.com': 'confluence',
  'jetbrains.com': 'jetbrains',
  'aws.amazon.com': 'amazonaws',
  'console.aws.amazon.com': 'amazonaws',
  'ovh.com': 'ovh',
  'hetzner.com': 'hetzner',
  // Amazon
  'amazon.com': 'amazon',
  'amazon.de': 'amazon',
  'amazon.co.uk': 'amazon',
  'amazon.fr': 'amazon',
  // Social / Messaging
  'discord.com': 'discord',
  'slack.com': 'slack',
  'telegram.org': 'telegram',
  't.me': 'telegram',
  'linkedin.com': 'linkedin',
  'reddit.com': 'reddit',
  'snapchat.com': 'snapchat',
  'tiktok.com': 'tiktok',
  'twitch.tv': 'twitch',
  'pinterest.com': 'pinterest',
  'tumblr.com': 'tumblr',
  'zoom.us': 'zoom',
  // Finance / Crypto
  'paypal.com': 'paypal',
  'stripe.com': 'stripe',
  'coinbase.com': 'coinbase',
  'binance.com': 'binance',
  'kraken.com': 'kraken',
  'bitpanda.com': 'bitpanda',
  'crypto.com': 'cryptocom',
  'etoro.com': 'etoro',
  'trading212.com': 'trading212',
  // Password Managers / Security
  'bitwarden.com': 'bitwarden',
  '1password.com': '1password',
  'lastpass.com': 'lastpass',
  'dashlane.com': 'dashlane',
  'keepersecurity.com': 'keepersecurity',
  'keeper.io': 'keepersecurity',
  'authy.com': 'twilio',
  'okta.com': 'okta',
  // Gaming
  'steampowered.com': 'steam',
  'store.steampowered.com': 'steam',
  'epicgames.com': 'epicgames',
  'battle.net': 'battlenet',
  'blizzard.com': 'battlenet',
  'ea.com': 'ea',
  'origin.com': 'ea',
  'ubisoft.com': 'ubisoft',
  'riotgames.com': 'riotgames',
  'leagueoflegends.com': 'riotgames',
  'playstation.com': 'playstation',
  'nintendo.com': 'nintendo',
  'gog.com': 'gogdotcom',
  // Cloud Storage
  'dropbox.com': 'dropbox',
  'box.com': 'box',
  // Email Providers
  'proton.me': 'proton',
  'protonmail.com': 'proton',
  'tutanota.com': 'tutanota',
  'tuta.com': 'tutanota',
  // Design / Productivity
  'figma.com': 'figma',
  'adobe.com': 'adobe',
  'canva.com': 'canva',
  'notion.so': 'notion',
  'wordpress.com': 'wordpress',
  'shopify.com': 'shopify',
  'mailchimp.com': 'mailchimp',
  'hubspot.com': 'hubspot',
  'salesforce.com': 'salesforce',
  'zendesk.com': 'zendesk',
  // Hosting / Domain
  'godaddy.com': 'godaddy',
  'namecheap.com': 'namecheap',
  'ionos.com': 'ionos',
  'strato.de': 'strato',
  // Banking (DE)
  'dkb.de': 'dkb',
  'ing.de': 'ing',
  'comdirect.de': 'comdirect',
};

/// Returns the Simple Icons CDN URL for [issuer] domain or [name], or null.
/// Appends `/000000` for light mode or `/ffffff` for dark mode so the
/// monochrome SVG matches the app theme.
String? simpleIconUrl(String issuer, String name, {bool isDark = false}) {
  final color = isDark ? 'ffffff' : '000000';
  final domain = issuer.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');

  // 1. Direct domain map
  final slug = _domainToSlug[domain];
  if (slug != null) return 'https://cdn.simpleicons.org/$slug/$color';

  // 2. First label of domain (e.g. "github" from "github.com")
  if (domain.isNotEmpty) {
    final label = domain.split('.').first;
    if (_domainToSlug.values.contains(label)) {
      return 'https://cdn.simpleicons.org/$label/$color';
    }
  }

  // 3. Normalized name (e.g. "GitHub" → "github")
  final normalized = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (normalized.isNotEmpty && _domainToSlug.values.contains(normalized)) {
    return 'https://cdn.simpleicons.org/$normalized/$color';
  }

  return null;
}

/// Returns the Google S2 favicon URL for [issuer] domain, or null.
String? faviconUrl(String issuer) {
  if (issuer.isEmpty) return null;
  return 'https://www.google.com/s2/favicons?domain=${Uri.encodeComponent(issuer)}&sz=64';
}
