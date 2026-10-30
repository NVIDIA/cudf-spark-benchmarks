
WITH customer_full_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        h.hd_income_band_sk,
        h.hd_buy_potential
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics h ON c.c_customer_sk = h.hd_demo_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        i.i_current_price
    FROM item i
),
sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
sales_with_product AS (
    SELECT 
        ss.ws_sold_date_sk,
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.total_discount,
        i.i_product_name,
        i.i_brand,
        i.i_category
    FROM sales_summary ss
    JOIN item_info i ON ss.ws_item_sk = i.i_item_sk
)
SELECT 
    c.full_name,
    c.ca_city,
    c.ca_state,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_purchase_estimate,
    c.cd_credit_rating,
    c.hd_income_band_sk,
    c.hd_buy_potential,
    s.ws_sold_date_sk,
    s.i_product_name,
    s.i_brand,
    s.i_category,
    s.total_quantity,
    s.total_sales,
    s.total_discount
FROM customer_full_info c
JOIN sales_with_product s ON c.c_customer_sk = s.ws_item_sk
WHERE c.cd_gender = 'F' 
  AND c.cd_marital_status = 'M' 
  AND s.total_sales > 100
ORDER BY s.total_sales DESC
LIMIT 100;
