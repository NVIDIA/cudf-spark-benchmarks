
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
segmented_sales AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        sd.total_sales,
        sd.order_count,
        CASE 
            WHEN sd.total_sales > 1000 THEN 'High Value'
            WHEN sd.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    customer_segment,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    SUM(order_count) AS total_orders
FROM 
    segmented_sales
GROUP BY 
    customer_segment
ORDER BY 
    CASE 
        WHEN customer_segment = 'High Value' THEN 1
        WHEN customer_segment = 'Medium Value' THEN 2
        WHEN customer_segment = 'Low Value' THEN 3
    END;
