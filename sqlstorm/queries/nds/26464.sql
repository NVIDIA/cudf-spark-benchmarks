
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales
    FROM
        web_sales ws
    JOIN 
        customer_info c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_sk
),
state_count AS (
    SELECT
        ca.ca_state,
        COUNT(*) AS customer_count
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_state
),
final_output AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        ss.total_orders,
        ss.total_sales,
        sc.customer_count
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.customer_sk
    LEFT JOIN 
        state_count sc ON ci.ca_state = sc.ca_state
)
SELECT
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    total_orders,
    total_sales,
    customer_count,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        WHEN total_sales < 100 THEN 'Low Sales'
        WHEN total_sales < 1000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    final_output
WHERE 
    cd_gender = 'F' AND 
    cd_marital_status = 'M' AND 
    customer_count > 50
ORDER BY 
    total_sales DESC;
