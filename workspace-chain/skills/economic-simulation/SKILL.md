# Economic Simulation

## Why Simulate Before Deploying

Every parameter in a DeFi protocol is a policy decision with economic consequences. Simulate first, or pay the price on mainnet.

## Agent-Based Simulation (Python)

```python
import numpy as np
from dataclasses import dataclass
from typing import List

@dataclass
class Agent:
    address: str
    usdc_balance: float
    yes_shares: float
    no_shares: float
    strategy: str  # 'informed', 'noise', 'arbitrageur', 'attacker'

class PredictionMarketSim:
    def __init__(self, b: float = 1000.0, initial_yes: float = 0.5):
        self.b = b  # LMSR liquidity parameter
        self.q_yes = b * np.log(initial_yes / (1 - initial_yes)) if initial_yes != 0.5 else 0
        self.q_no = 0
        self.agents: List[Agent] = []
        self.volume = 0
        self.prices_history = []

    def get_yes_price(self) -> float:
        import math
        exp_yes = math.exp(self.q_yes / self.b)
        exp_no = math.exp(self.q_no / self.b)
        return exp_yes / (exp_yes + exp_no)

    def buy_yes(self, amount: float) -> float:
        """Returns shares received for `amount` USDC"""
        import math
        before = self.b * math.log(math.exp(self.q_yes/self.b) + math.exp(self.q_no/self.b))
        self.q_yes += amount
        after = self.b * math.log(math.exp(self.q_yes/self.b) + math.exp(self.q_no/self.b))
        cost = after - before
        return amount  # simplified

    def simulate_round(self, true_probability: float):
        """One round of trading"""
        for agent in self.agents:
            if agent.strategy == 'informed':
                # Informed traders: buy YES if price < true probability
                current_price = self.get_yes_price()
                edge = true_probability - current_price

                if edge > 0.02:  # More than 2% edge
                    amount = min(agent.usdc_balance * 0.1, edge * 1000)
                    self.buy_yes(amount)
                    agent.usdc_balance -= amount
                    agent.yes_shares += amount

            elif agent.strategy == 'noise':
                # Noise traders: random direction, small size
                direction = np.random.choice([True, False])
                amount = np.random.uniform(10, 100)
                if direction:
                    self.buy_yes(amount)
                else:
                    self.q_no += amount  # buy_no

        self.prices_history.append(self.get_yes_price())

def run_simulation(n_agents: int = 1000, n_rounds: int = 100, true_prob: float = 0.65):
    market = PredictionMarketSim(b=10000)

    # Create agent population
    for i in range(n_agents):
        strategy = np.random.choice(
            ['informed', 'noise', 'arbitrageur'],
            p=[0.1, 0.8, 0.1]  # 10% informed, 80% noise, 10% arb
        )
        market.agents.append(Agent(
            address=f"0x{i:040x}",
            usdc_balance=np.random.lognormal(mean=6, sigma=1.5),  # Log-normal wealth
            yes_shares=0,
            no_shares=0,
            strategy=strategy
        ))

    for _ in range(n_rounds):
        market.simulate_round(true_prob)

    # Analysis
    final_price = market.get_yes_price()
    price_error = abs(final_price - true_prob)
    print(f"True probability: {true_prob:.2%}")
    print(f"Market price after {n_rounds} rounds: {final_price:.2%}")
    print(f"Price error: {price_error:.2%}")
    print(f"Market calibration: {'GOOD' if price_error < 0.05 else 'POOR'}")

    return market.prices_history

run_simulation()
```

## CadCAD for Complex Token Systems

```python
# cadCAD: state-transition framework for complex systems
from cadCAD.configuration import Experiment
from cadCAD.configuration.utils import config_sim
from cadCAD import configs

# Define state variables
genesis_states = {
    'prize_pool': 10000.0,        # USDC in pool
    'active_agents': 100,
    'platform_revenue': 0.0,
    'sybil_attacks': 0,
    'honest_participants': 90,
    'sybil_participants': 10,
}

# System parameters to test
system_params = {
    'platform_rake': [0.05, 0.10, 0.15],     # Test 3 rake levels
    'sybil_resistance_cost': [10, 50, 100],   # Cost to create fake identity
    'min_stake': [0, 10, 100],                # Minimum stake to enter
}

# State update functions
def update_sybil_attacks(params, step, sH, s, _input):
    # Sybil attack is profitable if: entry_cost * n_entries < expected_winnings
    entry_cost = params['min_stake']
    expected_win = s['prize_pool'] * (1 - params['platform_rake']) / s['active_agents']
    is_profitable = expected_win > entry_cost

    new_sybils = s['sybil_participants'] + (5 if is_profitable else -1)
    return 'sybil_participants', max(0, new_sybils)

def update_platform_revenue(params, step, sH, s, _input):
    new_revenue = s['platform_revenue'] + s['prize_pool'] * params['platform_rake']
    return 'platform_revenue', new_revenue

# Run simulation across all parameter combinations
# cadCAD sweeps all combinations automatically
```

## Parameter Optimization via Simulation

### Finding Optimal Liquidation Bonus (Lending Protocol)
```python
def simulate_liquidations(bonus: float, n_positions: int = 1000, crash_magnitude: float = 0.4):
    """
    Simulate a 40% price crash and measure:
    - What % of underwater positions get liquidated?
    - What's the total protocol deficit?
    - What's total liquidator profit?
    """
    # Create random positions
    collateral_ratios = np.random.uniform(1.2, 3.0, n_positions)
    positions = [{'collateral': r, 'debt': 1.0} for r in collateral_ratios]

    # Apply crash
    new_collateral = [p['collateral'] * (1 - crash_magnitude) for p in positions]

    # Find liquidatable positions
    underwater = [i for i, c in enumerate(new_collateral) if c < 1.05]  # HF < 1.05

    liquidated = 0
    deficit = 0
    liquidator_profit = 0

    for i in underwater:
        c = new_collateral[i]
        d = positions[i]['debt']

        # Will a liquidator bother? Need bonus > gas cost
        potential_profit = d * bonus - d  # Profit = bonus * debt - debt repaid
        if potential_profit > 0.01:  # Gas cost threshold
            liquidated += 1
            if c + bonus > d:
                liquidator_profit += potential_profit
            else:
                deficit += d - c  # Protocol absorbs deficit

    liquidation_rate = liquidated / len(underwater) if underwater else 1.0
    return {
        'liquidation_rate': liquidation_rate,
        'deficit': deficit,
        'liquidator_profit': liquidator_profit,
        'unliquidated_bad_debt': len(underwater) - liquidated
    }

# Sweep bonus values from 1% to 20%
results = {}
for bonus in np.arange(0.01, 0.21, 0.01):
    results[bonus] = simulate_liquidations(bonus)

# Find optimal: maximize liquidation_rate while minimizing deficit
# Typically 5-10% for volatile assets, 1-3% for stablecoins/correlated assets
```

## Stress Testing Scenarios

```python
def stress_test_prediction_market(market):
    scenarios = {
        'flash_crash': lambda: market.apply_shock(-0.5),          # 50% price drop
        'bank_run': lambda: market.mass_redemption(0.8),           # 80% of users exit
        'oracle_failure': lambda: market.freeze_oracle(3600),      # 1 hour no update
        'whale_manipulation': lambda: market.whale_bet(0.3, True), # 30% of pool on YES
        'sybil_swarm': lambda: market.add_sybils(1000),            # 1000 fake accounts
    }

    for name, scenario_fn in scenarios.items():
        state_before = market.snapshot()
        try:
            scenario_fn()
            state_after = market.snapshot()

            print(f"\n{name}:")
            print(f"  Solvency: {'MAINTAINED' if state_after.solvent else 'BROKEN'}")
            print(f"  Price accuracy: {state_after.price_error:.2%}")
            print(f"  User losses: ${state_after.user_losses:.2f}")

        except Exception as e:
            print(f"{name}: SYSTEM FAILURE — {e}")
        finally:
            market.restore(state_before)
```

## Key Simulation Insights for Protocol Design

| Question | Simulation Reveals |
|----------|-------------------|
| What liquidation bonus? | Too low = no liquidators, bad debt. Too high = users lose unfairly. Optimal is asset-specific. |
| What LMSR b parameter? | Too low = price moves too much per trade. Too high = market maker loses too much. |
| What platform rake? | Too high = users go elsewhere. Too low = unsustainable. ~1-5% typical. |
| Sybil resistance threshold? | Minimum stake that makes Sybil attacks unprofitable at expected prize pool size. |
| Dispute bond size? | Must exceed expected dispute frequency × resolution cost. |
