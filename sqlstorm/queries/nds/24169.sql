
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
), 

AggSales AS (
    SELECT 
        sc.ws_item_sk,
        sc.total_quantity,
        sc.total_profit,
        CASE 
            WHEN sc.total_profit > 1000 THEN 'High Profit'
            WHEN sc.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END AS profit_category
    FROM SalesCTE sc
)

SELECT 
    ca.ca_address_id,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name)) AS customer_names,
    SUM(a.total_quantity) AS total_quantity_sold,
    SUM(a.total_profit) AS total_profit,
    SUM(CASE WHEN a.profit_category = 'High Profit' THEN a.total_profit ELSE 0 END) AS high_profit_sum,
    COALESCE(MAX(ab.ib_upper_bound), 0) AS highest_income_band
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN AggSales a ON c.c_customer_sk = a.ws_item_sk
LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ab ON hd.hd_income_band_sk = ab.ib_income_band_sk
WHERE 
    ca.ca_state IS NOT NULL
    AND (c.c_birth_year IS NULL OR c.c_birth_year <= 1990)
GROUP BY 
    ca.ca_address_id
HAVING 
    SUM(a.total_quantity) > (SELECT AVG(total_quantity) FROM AggSales)
ORDER BY 
    total_profit DESC
LIMIT 10 OFFSET 5;
