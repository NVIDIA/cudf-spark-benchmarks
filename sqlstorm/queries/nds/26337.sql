
WITH addr_info AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
cust_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk, 
        ws.ws_bill_customer_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_current_price
    FROM 
        item i
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_purchase_estimate,
    c.cd_credit_rating,
    s.total_sold,
    s.total_revenue,
    i.i_product_name,
    i.i_brand,
    i.i_current_price
FROM 
    addr_info a
JOIN 
    cust_info c ON a.ca_address_sk = c.c_customer_sk
JOIN 
    sales_info s ON c.c_customer_sk = s.ws_bill_customer_sk
JOIN 
    item_info i ON s.ws_item_sk = i.i_item_sk
WHERE 
    a.ca_state = 'CA' 
    AND c.cd_gender = 'M' 
    AND s.total_sold > 100 
ORDER BY 
    s.total_revenue DESC
LIMIT 50;
