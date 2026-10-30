
WITH  sales_rank AS (
    SELECT 
        ws_bill_customer_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
),
customer_income AS (
    SELECT 
        c.c_customer_sk,
        household.hd_income_band_sk,
        household.hd_buy_potential,
        COUNT(DISTINCT s.ss_ticket_number) AS total_store_sales
    FROM 
        customer AS c
    LEFT JOIN 
        household_demographics AS household ON c.c_current_hdemo_sk = household.hd_demo_sk
    LEFT JOIN 
        store_sales AS s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk,
        household.hd_income_band_sk,
        household.hd_buy_potential
),
final_stats AS (
    SELECT 
        ci.c_customer_sk,
        ci.hd_income_band_sk,
        ci.hd_buy_potential,
        ci.total_store_sales,
        COUNT(sr.ws_item_sk) AS total_web_sales,
        SUM(sr.ws_net_profit) AS total_profit
    FROM 
        customer_income AS ci
    LEFT JOIN 
        sales_rank AS sr ON ci.c_customer_sk = sr.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_sk, 
        ci.hd_income_band_sk, 
        ci.hd_buy_potential, 
        ci.total_store_sales
)
SELECT 
    f.hd_income_band_sk,
    f.hd_buy_potential,
    f.total_store_sales,
    f.total_web_sales,
    f.total_profit,
    f.total_profit / NULLIF(f.total_store_sales, 0) AS profit_ratio
FROM 
    final_stats AS f
WHERE 
    f.total_profit > 0
ORDER BY 
    f.total_profit DESC
LIMIT 10;
