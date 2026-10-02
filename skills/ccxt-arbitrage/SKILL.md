---
name: ccxt-arbitrage
description: "Expert in CCXT, High-Frequency Trading (HFT) and Crypto Arbitrage. Covers Binance async API, slippage calculation, orderbook fetching, and low-latency architectural patterns."
risk: unknown
source: community
date_added: "2026-02-28"
---

# CCXT Arbitrage & HFT Skill

Use this skill when the user wants to build cryptocurrency arbitrage bots, especially triangular arbitrage, high-frequency trading (HFT), and CCXT asynchronous integration.

## Principles of Arbitrage bots

1. **Latency is king**: Use WebSockets for orderbook (Market Data) streams. REST APIs are too slow for real arbitrage and should only be used as fallbacks or for executing orders.
2. **Slippage is the enemy**: Always account for the order book depth. A quoted spread of 0.2% might become -0.1% if there isn't enough volume at the best bid/ask to fill the order.
3. **Fee modeling**: Binance exacts 0.1% per trade standard, or 0.075% with BNB. In a triangular trade (A -> B -> C -> A), you pay fees 3 times. Total fee = 3 * 0.075% = 0.225%. The spread MUST clearly exceed this to be profitable.
4. **Execution Risk**: Triangular arbitrage is not atomic. If the first leg executes but the second leg fails or the price moves, you are exposed to market risk (Open position). Limit orders are safer but may not fill; Market orders guarantee execution but suffer slippage.

## Best Practices with CCXT Python

- **Async always**: Use `ccxt.pro` or `import ccxt.async_support as ccxt` for non-blocking I/O.
- **Handling Rates**: Respect rate limits, otherwise Binance IP bans.
- **Environment**: Keep API keys in `.env` securely. Never log keys.
- **Architecture Validation**: Run in `dry-run` or Paper Trading mode collecting slippage and orderbook latency before executing real capital.

## Basic Structure of `ccxt` Async

```python
import ccxt.async_support as ccxt
import asyncio

async def fetch_ticker():
    exchange = ccxt.binance({
        'apiKey': 'YOUR_API_KEY',
        'secret': 'YOUR_SECRET',
        'enableRateLimit': True,
    })
    
    # Binance specific: using BNB for fees
    exchange.options['createMarketBuyOrderRequiresPrice'] = False
    
    orderbook = await exchange.fetch_order_book('BTC/USDT')
    best_bid = orderbook['bids'][0][0] if len(orderbook['bids']) > 0 else None
    best_ask = orderbook['asks'][0][0] if len(orderbook['asks']) > 0 else None
    
    await exchange.close()
    return best_bid, best_ask
```

## Security Posture

- Only allow 'Read' and 'Spot Trading' in Binance API settings. Withdrawals MUST be disabled.
- The API KEY must be IP Whitelisted to the VPS.
- Create explicit local Kill-Switches.
- Ensure proper logging using Python `logging` module so all transactions and spreads have audit trails.
