
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        LOWER(TRIM(ca_city)) AS city_lowercase,
        CONCAT(TRIM(ca_zip), '-', TRIM(ca_state)) AS location_info
    FROM 
        customer_address
),
filtered_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        pd.full_address,
        pd.city_lowercase,
        pd.location_info
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses pd ON c.c_current_addr_sk = pd.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_education_status LIKE '%Bachelor%'
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    fc.full_name,
    fc.city_lowercase,
    fc.location_info,
    ss.total_orders,
    ss.total_profit
FROM 
    filtered_customers fc
LEFT JOIN 
    sales_summary ss ON fc.c_customer_sk = ss.ws_bill_customer_sk
ORDER BY 
    ss.total_profit DESC
LIMIT 10;
