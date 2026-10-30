
WITH  customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
high_value_customers AS (
    SELECT 
        * 
    FROM customer_stats 
    WHERE total_web_profit IS NOT NULL AND total_web_profit > (
        SELECT AVG(total_web_profit) 
        FROM customer_stats 
        WHERE total_orders > 0
    )
),
customer_details AS (
    SELECT 
        h.hd_income_band_sk,
        h.hd_buy_potential,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(c.c_birth_country, 'Unknown') AS c_birth_country
    FROM household_demographics h
    JOIN customer c ON h.hd_demo_sk = c.c_current_cdemo_sk
)

SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    COALESCE(cdl.hd_buy_potential, 'Not Available') AS purchase_potential,
    cd.c_birth_country,
    CASE 
        WHEN hvc.total_orders > 5 THEN 'Frequent Buyer' 
        ELSE 'Occasional Buyer' 
    END AS buyer_type,
    RANK() OVER (ORDER BY hvc.total_web_profit DESC) AS profit_rank
FROM high_value_customers hvc
LEFT JOIN customer_details cd ON hvc.c_customer_sk = cd.c_customer_sk
FULL OUTER JOIN customer_details cdl ON cd.hd_income_band_sk = cdl.hd_income_band_sk
WHERE (cdl.hd_buy_potential IS NULL OR cdl.hd_buy_potential LIKE 'High%')
   AND (cd.c_birth_country IS NOT NULL OR hvc.total_web_profit IS NULL)
ORDER BY profit_rank ASC
LIMIT 10;
