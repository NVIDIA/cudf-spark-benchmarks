
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE d_year = 2023
    GROUP BY ws_item_sk
),
item_details AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_brand,
        i_current_price
    FROM item
),
top_items AS (
    SELECT 
        id.i_item_sk,
        id.i_product_name,
        id.i_brand,
        id.i_current_price,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_net_profit,
        ss.total_orders
    FROM item_details id
    JOIN sales_summary ss ON id.i_item_sk = ss.ws_item_sk
    ORDER BY ss.total_sales DESC
    LIMIT 10
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
final_summary AS (
    SELECT 
        ti.i_item_sk,
        ti.i_product_name,
        ti.i_brand,
        ti.total_quantity,
        ti.total_sales,
        cs.c_first_name,
        cs.c_last_name,
        cs.orders_count
    FROM top_items ti
    JOIN customer_summary cs ON ti.total_orders IN (SELECT orders_count FROM customer_summary)
)
SELECT 
    f.i_item_sk,
    f.i_product_name,
    f.i_brand,
    f.total_quantity,
    f.total_sales,
    f.c_first_name,
    f.c_last_name
FROM final_summary f
WHERE f.orders_count > 5
ORDER BY f.total_sales DESC;
