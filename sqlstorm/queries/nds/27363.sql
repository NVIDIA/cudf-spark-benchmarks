
WITH 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
avg_sales AS (
    SELECT 
        AVG(total_sales) AS average_sales
    FROM 
        sales_data
),
ranked_customers AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_zip,
        sd.total_sales,
        sd.order_count,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        sd.total_sales > (SELECT average_sales FROM avg_sales)
)

SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_zip,
    total_sales,
    order_count,
    sales_rank
FROM 
    ranked_customers
WHERE 
    sales_rank <= 10
ORDER BY 
    sales_rank;
