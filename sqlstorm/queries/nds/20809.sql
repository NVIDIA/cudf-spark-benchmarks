
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank,
        COUNT(*) OVER (PARTITION BY ws_item_sk) AS sale_count
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
HighProfitItems AS (
    SELECT 
        ws_item_sk,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_sales_count
    FROM 
        RankedSales
    WHERE 
        profit_rank = 1
    GROUP BY 
        ws_item_sk
),
FilteredCustomer AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        COALESCE(hd_income_band_sk, -1) AS income_band_sk
    FROM 
        customer
    LEFT JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    LEFT JOIN 
        household_demographics ON c_customer_sk = hd_demo_sk
    WHERE 
        cd_gender = 'F' 
        AND (cd_purchase_estimate IS NULL OR cd_purchase_estimate > 1000)
),
CustomerStatistics AS (
    SELECT 
        fc.c_customer_sk, 
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_spent
    FROM 
        FilteredCustomer fc
    LEFT JOIN 
        web_sales ws ON fc.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        fc.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_spent,
    hpi.total_net_profit,
    hpi.avg_sales_price,
    CASE 
        WHEN cs.total_spent > hpi.total_net_profit THEN 'High Roller'
        ELSE 'Average Joe' 
    END AS customer_category,
    RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
FROM 
    CustomerStatistics cs
JOIN 
    HighProfitItems hpi ON cs.order_count = hpi.total_sales_count  
LEFT JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE 
    (c.c_birth_month IS NULL OR c.c_birth_month IN (1, 6, 12))
    AND hpi.avg_sales_price BETWEEN 10 AND 50
ORDER BY 
    cs.total_spent DESC
LIMIT 100;
