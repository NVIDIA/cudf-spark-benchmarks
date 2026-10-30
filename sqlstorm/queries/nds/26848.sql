
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        TRIM(UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type))) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
), 
distinct_cities AS (
    SELECT 
        DISTINCT ca_city
    FROM 
        processed_addresses
),
filtered_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        d.cd_gender,
        d.cd_marital_status,
        da.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        processed_addresses da ON c.c_current_addr_sk = da.ca_address_sk
    WHERE 
        da.ca_city IN (SELECT ca_city FROM distinct_cities WHERE ca_city LIKE '%VILLE%')
),
sales_summary AS (
    SELECT 
        fc.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        filtered_customers fc
    LEFT JOIN 
        web_sales ws ON fc.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        fc.c_customer_sk
)
SELECT 
    fc.c_customer_sk,
    fc.c_first_name,
    fc.c_last_name,
    ss.total_orders,
    ss.total_profit,
    CASE 
        WHEN ss.total_profit > 1000 THEN 'High Value'
        WHEN ss.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category 
FROM 
    filtered_customers fc
LEFT JOIN 
    sales_summary ss ON fc.c_customer_sk = ss.c_customer_sk
ORDER BY 
    ss.total_profit DESC, 
    fc.c_last_name ASC;
