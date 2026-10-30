
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS average_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(i.i_current_price, 0) AS current_price,
        COALESCE(i.i_wholesale_cost, 0) AS wholesale_cost
    FROM item i
    LEFT JOIN sales_summary ss ON i.i_item_sk = ss.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    id.i_item_desc,
    id.current_price,
    id.wholesale_cost,
    COALESCE(ss.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(ss.total_sales, 0) AS total_sales,
    ss.average_net_profit,
    CASE 
        WHEN ci.income_band IS NOT NULL THEN 'Has Income Band'
        ELSE 'No Income Band'
    END AS income_band_status
FROM customer_info ci
JOIN item_details id ON ci.c_customer_sk = id.i_item_sk
LEFT JOIN sales_summary ss ON id.i_item_sk = ss.ws_item_sk
WHERE (ss.total_sales > 1000 OR ci.cd_gender = 'M')
ORDER BY total_sales DESC
LIMIT 50;
