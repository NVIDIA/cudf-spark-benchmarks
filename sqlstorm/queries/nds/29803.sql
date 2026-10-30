
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        LOWER(TRIM(ca_street_name)) AS processed_street_name,
        CONCAT(LOWER(TRIM(ca_city)), ', ', ca_state) AS city_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
),
customer_full_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        pd.processed_street_name,
        pd.city_state,
        pd.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses pd ON c.c_current_addr_sk = pd.ca_address_sk
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cfi.full_name,
    cfi.cd_gender,
    cfi.cd_marital_status,
    cfi.processed_street_name,
    cfi.city_state,
    COALESCE(si.total_profit, 0) AS total_profit,
    COALESCE(si.total_orders, 0) AS total_orders
FROM 
    customer_full_info cfi
LEFT JOIN 
    sales_info si ON cfi.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    cfi.cd_gender = 'F' 
    AND cfi.cd_marital_status = 'M'
ORDER BY 
    total_profit DESC
LIMIT 10;
