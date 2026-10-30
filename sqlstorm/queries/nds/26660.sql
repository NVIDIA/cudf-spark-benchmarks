
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS upper_full_name,
        LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS lower_full_name
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
merged_data AS (
    SELECT 
        ci.c_customer_sk,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        COALESCE(sd.total_sales, 0) AS total_sales
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    total_sales,
    CASE 
        WHEN total_sales = 0 THEN 'No Sales'
        WHEN total_sales < 100 THEN 'Low Sales'
        WHEN total_sales BETWEEN 100 AND 500 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    merged_data
WHERE 
    LENGTH(full_name) > 10
ORDER BY 
    total_sales DESC, full_name ASC
LIMIT 100;
