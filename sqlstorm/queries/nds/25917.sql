
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate >= 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate >= 500 THEN 'Medium'
            ELSE 'Low' 
        END AS purchase_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
final AS (
    SELECT 
        pa.ca_address_sk,
        ci.full_name,
        ci.cd_gender,
        ci.purchase_category,
        sd.total_sales,
        sd.total_profit
    FROM 
        processed_addresses pa
    JOIN 
        customer_info ci ON pa.ca_address_sk = ci.c_customer_sk
    JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
)
SELECT 
    ca_address_sk,
    full_name,
    cd_gender,
    purchase_category,
    total_sales,
    total_profit
FROM 
    final
WHERE 
    total_sales > 5
ORDER BY 
    total_profit DESC
LIMIT 100;
