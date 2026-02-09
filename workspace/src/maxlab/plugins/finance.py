"""
FinancePlugin: Semantic Kernel plugin for financial data analysis.

Provides kernel functions for:
- Transaction categorization
- Spend pattern analysis
- Budget insights
- RBC/TD bank data interpretation
"""

import logging
from typing import Annotated

from semantic_kernel.functions import kernel_function

logger = logging.getLogger(__name__)


class FinancePlugin:
    """
    A Semantic Kernel plugin for financial analysis and transaction processing.
    
    Integrates with MaxLab's bank data (RBC, TD) to provide intelligent
    categorization, pattern analysis, and financial insights.
    """
    
    @kernel_function(
        description="Suggest a transaction category based on merchant name and description",
        name="categorize_transaction"
    )
    def categorize_transaction(
        self,
        merchant: Annotated[str, "Merchant name or description"],
        amount: Annotated[float, "Transaction amount"] = 0.0,
    ) -> Annotated[str, "Suggested category for the transaction"]:
        """
        Suggest a transaction category.
        
        Args:
            merchant: The merchant or transaction description
            amount: Optional transaction amount (for context)
            
        Returns:
            Suggested category (e.g., "Groceries", "Dining", "Utilities")
        """
        merchant_lower = merchant.lower()
        
        # Common category patterns
        categories = {
            "Groceries": [
                "supermarket", "grocery", "whole foods", "costco", "safeway",
                "kroger", "walmart", "trader joe", "loblaws", "metro", "sobeys"
            ],
            "Dining": [
                "restaurant", "cafe", "coffee", "pizza", "burger", "sushi",
                "bar", "pub", "diner", "bistro", "grill", "rhubarb"
            ],
            "Gas": [
                "shell", "esso", "bp", "chevron", "sunoco", "petro",
                "gas station", "fuel", "petrol"
            ],
            "Utilities": [
                "hydro", "electric", "water", "gas bill", "internet", "phone",
                "bell", "rogers", "telecom", "utility"
            ],
            "Transportation": [
                "uber", "lyft", "taxi", "transit", "parking", "toll",
                "Go transit", "ttc", "parking meter", "car wash"
            ],
            "Entertainment": [
                "movie", "cinema", "theater", "spotify", "netflix", "apple music",
                "gaming", "steam", "concert", "ticket"
            ],
            "Shopping": [
                "amazon", "ebay", "mall", "store", "shop", "retail",
                "clothing", "apparel", "target", "best buy"
            ],
            "Health": [
                "pharmacy", "doctor", "hospital", "clinic", "dentist",
                "medical", "gym", "fitness", "wellness"
            ],
            "Travel": [
                "hotel", "airline", "airbnb", "booking", "expedia",
                "resort", "motel", "flight", "train"
            ],
            "Subscriptions": [
                "subscription", "membership", "adobe", "microsoft", "github",
                "monthly", "annual fee"
            ],
        }
        
        for category, keywords in categories.items():
            if any(keyword in merchant_lower for keyword in keywords):
                return category
        
        # Default category based on amount
        if amount > 500:
            return "Large Purchase"
        elif amount > 100:
            return "Shopping"
        else:
            return "Other"
    
    @kernel_function(
        description="Analyze spending patterns across a set of transactions",
        name="analyze_spending_patterns"
    )
    def analyze_spending_patterns(
        self,
        transaction_summary: Annotated[
            str,
            "Summary of transactions with dates, amounts, and categories"
        ],
    ) -> Annotated[str, "Analysis of spending patterns"]:
        """
        Analyze spending patterns from a transaction summary.
        
        Args:
            transaction_summary: Transaction data summary
            
        Returns:
            Identified spending patterns and trends
        """
        patterns = []
        
        # Pattern detection hints for the agent
        if "daily" in transaction_summary.lower():
            patterns.append("Frequent daily transactions detected - review for essential vs. discretionary spending")
        
        if "high" in transaction_summary.lower() and "category" in transaction_summary.lower():
            patterns.append("High spending category identified - consider budget reallocation")
        
        if "recurring" in transaction_summary.lower() or "monthly" in transaction_summary.lower():
            patterns.append("Recurring monthly charges detected - opportunity for subscription audit")
        
        if "weekend" in transaction_summary.lower():
            patterns.append("Weekend vs weekday spending patterns observable")
        
        if "peak" in transaction_summary.lower():
            patterns.append("Peak spending periods identified - seasonal trend analysis recommended")
        
        if not patterns:
            patterns.append("Transaction summary provided. Aggregate by category for pattern analysis.")
        
        return "\n".join(f"• {pattern}" for pattern in patterns)
    
    @kernel_function(
        description="Suggest budget targets based on spending analysis",
        name="suggest_budget_targets"
    )
    def suggest_budget_targets(
        self,
        category: Annotated[str, "Spending category"],
        historical_average: Annotated[float, "Average monthly spending in this category"] = 0.0,
        available_budget: Annotated[float, "Total available monthly budget"] = 0.0,
    ) -> Annotated[str, "Budget target recommendation"]:
        """
        Suggest target budget for a spending category.
        
        Args:
            category: The spending category
            historical_average: Historical average spending
            available_budget: Total budget available
            
        Returns:
            Budget target recommendation
        """
        budgets = {
            "Groceries": 0.15,  # 15% of budget
            "Dining": 0.10,     # 10% of budget
            "Gas": 0.08,        # 8% of budget
            "Utilities": 0.08,  # 8% of budget
            "Transportation": 0.12,  # 12% of budget
            "Entertainment": 0.08,   # 8% of budget
            "Shopping": 0.15,   # 15% of budget
            "Health": 0.08,     # 8% of budget
            "Travel": 0.10,     # 10% of budget
        }
        
        target_pct = budgets.get(category, 0.10)
        
        if available_budget > 0:
            recommended = available_budget * target_pct
            current_pct = (historical_average / available_budget) * 100 if available_budget > 0 else 0
            
            if current_pct > target_pct * 100 * 1.2:
                status = f"⚠️  Currently {current_pct:.1f}% - {int((current_pct - target_pct * 100) / 10) * 10}% over target"
            elif current_pct < target_pct * 100 * 0.8:
                status = f"✅ Currently {current_pct:.1f}% - under budget"
            else:
                status = f"✅ Currently {current_pct:.1f}% - on track"
            
            return f"Target budget for {category}: ${recommended:,.2f} (23% of budget). {status}"
        
        return f"Recommended allocation for {category}: {target_pct * 100:.0f}% of total budget"
    
    @kernel_function(
        description="Generate insights about RBC/TD bank account activity",
        name="analyze_bank_activity"
    )
    def analyze_bank_activity(
        self,
        bank: Annotated[str, "Bank name (RBC, TD, etc.)"],
        account_type: Annotated[str, "Account type (checking, savings, credit card)"],
        summary: Annotated[str, "Summary of account activity"],
    ) -> Annotated[str, "Insights about the account"]:
        """
        Analyze bank account activity for insights.
        
        Args:
            bank: Bank name
            account_type: Type of account
            summary: Activity summary
            
        Returns:
            Insights and recommendations
        """
        insights = []
        
        if "rbc" in bank.lower():
            insights.append(f"RBC {account_type} account analysis:")
        elif "td" in bank.lower():
            insights.append(f"TD {account_type} account analysis:")
        else:
            insights.append(f"{bank} {account_type} account analysis:")
        
        # Add context-specific insights
        if "credit card" in account_type.lower():
            insights.append("• Monitor balance to avoid interest charges")
            insights.append("• Track spending across merchants")
            insights.append("• Review reward program utilization")
        elif "checking" in account_type.lower():
            insights.append("• Payment flow analysis recommended")
            insights.append("• Identify regular recurring charges")
            insights.append("• Optimize transaction timing")
        elif "savings" in account_type.lower():
            insights.append("• Monitor interest rates vs. alternatives")
            insights.append("• Track balance growth trends")
            insights.append("• Consider goal-based sub-accounts")
        
        return "\n".join(insights)
    
    @kernel_function(
        description="Identify potential savings opportunities",
        name="identify_savings_opportunities"
    )
    def identify_savings_opportunities(
        self,
        spending_data: Annotated[str, "Summary of spending patterns and categories"],
    ) -> Annotated[str, "List of potential savings opportunities"]:
        """
        Identify potential areas for savings.
        
        Args:
            spending_data: Summary of spending patterns
            
        Returns:
            Suggested savings opportunities
        """
        opportunities = []
        
        # Common suggestions
        opportunities.append("🎯 General Savings Opportunities:")
        opportunities.append("• Review subscriptions and cancel unused services")
        opportunities.append("• Consolidate bank accounts to reduce fees")
        opportunities.append("• Review credit card terms for optimal rewards")
        opportunities.append("• Consider automated savings transfers")
        
        # Context-specific based on spending data
        if "food" in spending_data.lower() or "dining" in spending_data.lower():
            opportunities.append("• Reduce dining out frequency or use discount platforms")
        
        if "entertainment" in spending_data.lower():
            opportunities.append("• Share streaming service subscriptions with family")
        
        if "shopping" in spending_data.lower():
            opportunities.append("• Use cashback apps for purchases")
        
        if "gas" in spending_data.lower() or "transportation" in spending_data.lower():
            opportunities.append("• Optimize routes or consider carpooling")
        
        return "\n".join(opportunities)
