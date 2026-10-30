
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        ws_item_sk AS item_sk,
        ws_quantity AS quantity,
        ws_sales_price AS sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
total_sales AS (
    SELECT 
        customer_sk,
        SUM(quantity * sales_price) AS total_spent
    FROM 
        ranked_sales
    WHERE 
        rank_sales <= 5
    GROUP BY 
        customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        coalesce(total.total_spent, 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        total_sales total ON c.c_customer_sk = total.customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name || ' ' || ci.c_last_name AS full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    CASE 
        WHEN ci.total_spent > 1000 THEN 'High Value'
        WHEN ci.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    COALESCE(sm.sm_carrier, 'Not Shipped') AS preferred_carrier
FROM 
    customer_info ci
LEFT JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    ci.total_spent IS NOT NULL
    AND ci.cd_gender IS NOT NULL
ORDER BY 
    ci.total_spent DESC;
