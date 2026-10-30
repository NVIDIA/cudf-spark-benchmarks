
WITH sales_summary AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ws_item_sk,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS customer_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
address_warehouse AS (
    SELECT 
        ca.ca_address_id,
        CASE 
            WHEN w.w_warehouse_sq_ft >= 100000 THEN 'Large'
            WHEN w.w_warehouse_sq_ft BETWEEN 50000 AND 99999 THEN 'Medium'
            ELSE 'Small'
        END AS warehouse_size
    FROM customer_address ca
    JOIN warehouse w ON ca.ca_address_sk = w.w_warehouse_sk
),
filtered_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_net_profit,
        cs.cs_net_profit AS catalog_profit,
        CASE 
            WHEN ws.ws_net_profit IS NULL THEN 'No Profit'
            WHEN ws.ws_net_profit > 0 THEN 'Profitable'
            ELSE 'Loss'
        END AS profit_status
    FROM web_sales ws
    LEFT JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
)

SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ss.total_sales,
    ss.total_orders,
    fs.ws_net_profit,
    fs.catalog_profit,
    fs.profit_status,
    aw.warehouse_size
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
LEFT JOIN filtered_sales fs ON fs.ws_item_sk = ss.ws_item_sk
LEFT JOIN address_warehouse aw ON aw.ca_address_id = ci.c_last_name
WHERE ci.customer_rank <= 5 
AND fs.profit_status <> 'No Profit'
AND EXISTS (
    SELECT 1 
    FROM store s 
    WHERE s.s_store_sk IN (
        SELECT DISTINCT sr_store_sk 
        FROM store_returns sr 
        WHERE sr_return_quantity > 1
    )
)
ORDER BY ss.total_sales DESC, ci.c_first_name ASC
LIMIT 20;
