
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
), 
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ss.total_sales,
        ss.order_count
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ci.rank <= 100
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(hvc.total_sales, 0) AS total_sales,
    hvc.order_count,
    CASE 
        WHEN hvc.order_count IS NULL THEN 'No Orders' 
        ELSE 'Placed Orders' 
    END AS order_status,
    CASE 
        WHEN hvc.total_sales > 1000 THEN 'High Value'
        WHEN hvc.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    customer c
LEFT JOIN 
    high_value_customers hvc ON c.c_customer_sk = hvc.c_customer_sk
WHERE 
    c.c_birth_year < 1980 AND 
    (c.c_preferred_cust_flag = 'Y' OR hvc.total_sales IS NOT NULL)
ORDER BY 
    total_sales DESC, 
    c.c_last_name ASC
LIMIT 50;
