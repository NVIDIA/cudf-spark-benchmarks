WITH  sales_analysis AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        customer_id,
        total_sales,
        order_count
    FROM 
        sales_analysis
    WHERE 
        rank <= 10
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_state = 'CA')
)
SELECT 
    tc.customer_id,
    cd.c_first_name,
    cd.c_last_name,
    tc.total_sales,
    tc.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE 
        WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
        WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM 
    top_customers tc
LEFT JOIN 
    customer_details cd ON tc.customer_id = cd.c_customer_sk
ORDER BY 
    tc.total_sales DESC;