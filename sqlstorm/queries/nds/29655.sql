
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        CHAR_LENGTH(ca_street_name) AS street_name_length,
        TRIM(UPPER(ca_city)) AS normalized_city
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'NY') 
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count,
        COALESCE(AVG(cd.cd_dep_count), 0) AS average_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cs.customer_full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.address_count,
    cs.average_dependents,
    COALESCE(ss.total_net_profit, 0) AS total_net_profit,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.total_quantity, 0) AS total_quantity
FROM 
    customer_summary cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
ORDER BY 
    total_net_profit DESC, cs.customer_full_name
LIMIT 100;
