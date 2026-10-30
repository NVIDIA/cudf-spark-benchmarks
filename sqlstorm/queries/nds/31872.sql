
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ws_sold_date_sk
    FROM web_sales
    GROUP BY ws_item_sk, ws_sold_date_sk
),
ranked_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        d.d_year,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY sd.total_sales DESC) AS sales_rank
    FROM sales_data sd
    JOIN date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
),
top_items AS (
    SELECT
        ws_item_sk,
        total_quantity,
        total_sales
    FROM ranked_sales
    WHERE sales_rank <= 10
),
customer_returns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_value, 0) AS total_return_value
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_returns cr ON c.c_customer_sk = cr.sr_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    td.total_quantity,
    td.total_sales
FROM customer_details cd
JOIN top_items td ON cd.c_customer_sk = td.ws_item_sk
WHERE cd.total_returns > 0
ORDER BY cd.total_returns DESC, cd.c_last_name, cd.c_first_name;
