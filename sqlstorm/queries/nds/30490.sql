
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_buy_potential,
        hd.hd_dep_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
), 
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_current_price
    FROM item i
    WHERE i.i_rec_end_date IS NULL
),
date_range AS (
    SELECT 
        d.d_date_sk,
        d.d_date 
    FROM date_dim d 
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    SUM(sd.total_sales) AS total_sales,
    COUNT(DISTINCT sd.ws_item_sk) AS unique_items_sold,
    AVG(ii.i_current_price) AS avg_item_price,
    MAX(sd.order_count) AS max_orders
FROM sales_data sd
JOIN customer_info ci ON sd.ws_item_sk = ci.c_customer_sk
JOIN item_info ii ON sd.ws_item_sk = ii.i_item_sk
JOIN date_range dr ON sd.ws_sold_date_sk = dr.d_date_sk
WHERE 
    ci.cd_gender = 'F' 
    AND ci.cd_marital_status = 'M' 
    AND ii.i_brand = 'BrandX'
GROUP BY 
    ci.c_customer_sk, 
    ci.c_first_name, 
    ci.c_last_name
ORDER BY 
    total_sales DESC
LIMIT 10;
