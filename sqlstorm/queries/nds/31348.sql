
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopProfitableItems AS (
    SELECT 
        ws_item_sk,
        total_profit
    FROM SalesCTE
    WHERE profit_rank <= 10
),
CustomerJoin AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS customer_total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_item_sk IN (SELECT ws_item_sk FROM TopProfitableItems)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    cj.c_customer_sk,
    cj.c_first_name,
    cj.c_last_name,
    cj.customer_total_profit,
    cj.order_count,
    COALESCE(avg_income.hd_average_income, 0) AS average_income,
    CASE 
        WHEN cj.customer_total_profit > 1000 THEN 'High Value'
        WHEN cj.customer_total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM CustomerJoin cj
LEFT JOIN (
    SELECT 
        hd_demo_sk,
        AVG(ib_upper_bound) AS hd_average_income
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY hd_demo_sk
) AS avg_income ON cj.c_customer_sk = avg_income.hd_demo_sk
ORDER BY cj.customer_total_profit DESC
LIMIT 100;
