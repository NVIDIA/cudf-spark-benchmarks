
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
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
        ca.ca_state
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.ca_city,
        ci.ca_state,
        rs.total_sales
    FROM 
        customer_info ci
    JOIN 
        ranked_sales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.sales_rank = 1
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_purchase_estimate,
    hvc.ca_city,
    hvc.ca_state,
    COALESCE(hvc.total_sales, 0) AS total_sales,
    CASE 
        WHEN hvc.cd_purchase_estimate > 100000 THEN 'High Value'
        WHEN hvc.cd_purchase_estimate BETWEEN 50000 AND 100000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    high_value_customers hvc
WHERE 
    hvc.ca_state IS NOT NULL
ORDER BY 
    hvc.total_sales DESC;
