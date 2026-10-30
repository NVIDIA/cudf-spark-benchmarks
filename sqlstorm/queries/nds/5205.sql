
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
), grouped_sales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount,
        DENSE_RANK() OVER (PARTITION BY sd.ws_sold_date_sk ORDER BY sd.total_sales DESC) as sales_rank
    FROM sales_data sd
), top_sales AS (
    SELECT 
        g.ws_sold_date_sk,
        g.ws_item_sk,
        g.total_quantity,
        g.total_sales,
        g.total_discount
    FROM grouped_sales g
    WHERE g.sales_rank <= 10
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_city,
    cd.ca_state,
    ts.ws_sold_date_sk,
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_sales,
    ts.total_discount
FROM customer_data cd
JOIN top_sales ts ON cd.c_customer_sk = ts.ws_item_sk
ORDER BY ts.ws_sold_date_sk, ts.total_sales DESC;
