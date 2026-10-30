
WITH address_data AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
customer_data AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ranked_sales AS (
    SELECT 
        ws_item_sk,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    addr.full_address,
    addr.ca_city,
    addr.ca_state,
    addr.ca_zip,
    addr.ca_country,
    cust.full_name,
    cust.cd_gender,
    cust.cd_marital_status,
    sales.total_quantity,
    sales.total_sales,
    sales.total_orders,
    rank.sales_rank
FROM 
    address_data addr
JOIN 
    customer_data cust ON addr.ca_address_sk = cust.c_customer_sk
JOIN 
    sales_data sales ON cust.c_customer_sk = sales.ws_item_sk
JOIN 
    ranked_sales rank ON sales.ws_item_sk = rank.ws_item_sk
WHERE 
    addr.ca_country = 'USA' AND
    cust.cd_gender = 'F' AND
    rank.sales_rank <= 10
ORDER BY 
    rank.sales_rank;
