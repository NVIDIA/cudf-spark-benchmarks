
WITH recent_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        ws_item_sk, 
        total_quantity,
        RANK() OVER (ORDER BY total_revenue DESC) AS rank
    FROM 
        recent_sales
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        DENSE_RANK() OVER(PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_by_customer AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_items_bought,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer_info c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    COALESCE(sb.total_items_bought, 0) AS items_bought,
    COALESCE(sb.total_orders, 0) AS orders_placed,
    CASE 
        WHEN ci.cd_purchase_estimate IS NULL THEN 'Unknown'
        WHEN ci.cd_purchase_estimate > 10000 THEN 'High Value'
        WHEN ci.cd_purchase_estimate BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    CASE 
        WHEN ci.gender_rank < 5 THEN 'Top 5'
        ELSE 'Others'
    END AS gender_rank_category
FROM 
    customer_info ci
LEFT JOIN 
    sales_by_customer sb ON ci.c_customer_sk = sb.c_customer_sk
WHERE 
    (ci.cd_marital_status = 'M' AND sb.total_orders > 3) 
    OR (ci.cd_marital_status = 'S' AND sb.total_orders = 0)
    OR (ci.cd_marital_status IS NULL)
ORDER BY 
    customer_value ASC, 
    ci.c_last_name, 
    ci.c_first_name
LIMIT 100;
