
WITH customer_data AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        hd.hd_income_band_sk,
        COALESCE(hd.hd_dep_count, 0) AS dep_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price
    FROM item i
    WHERE i.i_rec_start_date <= (SELECT MAX(d.d_date) FROM date_dim d)
      AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > (SELECT MAX(d.d_date) FROM date_dim d))
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    SUM(sd.total_quantity) AS total_quantity,
    SUM(sd.total_sales) AS total_sales,
    COUNT(DISTINCT sd.ws_item_sk) AS item_count,
    CASE 
        WHEN cd.dep_count > 3 THEN 'Large Family'
        WHEN cd.dep_count BETWEEN 1 AND 3 THEN 'Small Family'
        ELSE 'Single'
    END AS family_size,
    MAX(i.i_current_price) AS max_item_price,
    MIN(i.i_current_price) AS min_item_price
FROM customer_data cd
LEFT JOIN sales_data sd ON cd.c_customer_sk = sd.ws_sold_date_sk
LEFT JOIN item_details i ON sd.ws_item_sk = i.i_item_sk
GROUP BY 
    cd.c_customer_sk, cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.dep_count
HAVING 
    SUM(sd.total_sales) > 0
ORDER BY 
    total_sales DESC
LIMIT 100;
