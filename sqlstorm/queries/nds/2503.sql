
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
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
        ca.ca_state,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.total_quantity,
        ss.total_sales,
        ss.order_count,
        DENSE_RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        customer_info c
    JOIN 
        sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_quantity,
    tc.total_sales,
    tc.order_count,
    ci.purchase_category,
    CASE 
        WHEN ci.ca_city IS NULL THEN 'City Unknown'
        ELSE ci.ca_city
    END AS city,
    ci.ca_state
FROM 
    top_customers tc
JOIN 
    customer_info ci ON tc.c_customer_sk = ci.c_customer_sk
WHERE 
    tc.sales_rank <= 10
    AND (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
ORDER BY 
    tc.total_sales DESC;
