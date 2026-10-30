
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS price_rank,
        SUM(ws_quantity) OVER (PARTITION BY ws_bill_customer_sk) AS total_quantity
    FROM 
        web_sales
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_last_name) AS row_num
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
popular_items AS (
    SELECT 
        ri.ws_item_sk,
        SUM(ws_quantity) AS quantity_sold,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ri
    WHERE 
        ri.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ri.ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    pi.ws_item_sk,
    pi.quantity_sold,
    pi.unique_customers,
    COALESCE(rs.total_quantity, 0) AS total_quantity_purchased,
    CASE 
        WHEN ci.row_num <= 10 THEN 'Top 10 Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    customer_info ci
LEFT JOIN popular_items pi ON ci.c_customer_sk = pi.ws_item_sk
LEFT JOIN ranked_sales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk AND rs.price_rank = 1
WHERE 
    ci.c_customer_sk IS NOT NULL
ORDER BY 
    ci.ca_state, quantity_sold DESC;
