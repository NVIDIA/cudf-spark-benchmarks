
WITH sales_data AS (
    SELECT 
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_paid,
        ws_net_paid_inc_tax,
        ws_net_profit,
        ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_date_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
        AND ws_ext_sales_price IS NOT NULL
),
top_sales AS (
    SELECT 
        d.d_date,
        COALESCE(MAX(CASE WHEN sd.rn = 1 THEN sd.ws_net_profit END), 0) AS top_profit,
        COALESCE(SUM(sd.ws_net_paid), 0) AS total_net_paid,
        COUNT(sd.ws_net_paid) AS sale_count
    FROM 
        date_dim d
    LEFT JOIN 
        sales_data sd ON d.d_date_sk = sd.ws_ship_date_sk
    GROUP BY 
        d.d_date
),
customer_probabilities AS (
    SELECT 
        cd_marital_status,
        COUNT(CASE WHEN cd_purchase_estimate > 500 THEN 1 END) * 1.0 / COUNT(*) AS high_spender_prob,
        COUNT(CASE WHEN cd_purchase_estimate <= 500 THEN 1 END) * 1.0 / COUNT(*) AS low_spender_prob
    FROM 
        customer_demographics
    GROUP BY 
        cd_marital_status
),
cross_joined AS (
    SELECT 
        t.*, 
        cp.high_spender_prob,
        cp.low_spender_prob
    FROM 
        top_sales t
    CROSS JOIN 
        customer_probabilities cp
)
SELECT 
    cj.d_date,
    cj.top_profit,
    cj.total_net_paid,
    cj.sale_count,
    CASE 
        WHEN cj.top_profit = 0 THEN 'No profit'
        WHEN cj.top_profit > 1000 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    CASE 
        WHEN cj.high_spender_prob > 0.5 THEN 'High Chance of Spending'
        ELSE 'Low Chance of Spending'
    END AS customer_spending_probability
FROM 
    cross_joined cj
WHERE 
    cj.top_profit > (
        SELECT AVG(top_profit) 
        FROM cross_joined 
        WHERE top_profit IS NOT NULL
    )
ORDER BY 
    cj.sale_count DESC 
LIMIT 10;
