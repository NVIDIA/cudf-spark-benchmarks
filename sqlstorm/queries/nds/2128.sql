
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 10 LIMIT 1) 
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 10 ORDER BY d_date_sk DESC LIMIT 1)
),
top_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_ext_sales_price
    FROM 
        ranked_sales rs
    WHERE 
        rs.sales_rank = 1
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    COUNT(DISTINCT ts.ws_order_number) AS total_orders,
    SUM(ts.ws_ext_sales_price) AS total_sales,
    AVG(ts.ws_ext_sales_price) AS average_sales,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers
FROM 
    top_sales ts
JOIN 
    customer_info ci ON ts.ws_item_sk IN (
        SELECT 
            inv.inv_item_sk 
        FROM 
            inventory inv 
        WHERE 
            inv.inv_quantity_on_hand > 0
    )
GROUP BY 
    ci.ca_city, ci.ca_state, ci.cd_gender
HAVING 
    SUM(ts.ws_ext_sales_price) > 1000
ORDER BY 
    total_sales DESC;
