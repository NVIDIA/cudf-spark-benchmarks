
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(UPPER(ca_street_number), ' ', UPPER(ca_street_name), ' ', UPPER(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', UPPER(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
customer_segment AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    pa.full_address,
    pa.ca_city,
    pa.ca_state,
    cs.customer_count,
    ss.total_profit,
    ss.order_count
FROM 
    processed_addresses pa
LEFT JOIN 
    sales_summary ss ON pa.ca_address_sk = ss.ws_bill_addr_sk
LEFT JOIN 
    customer_segment cs ON pa.ca_state = cs.cd_gender
WHERE 
    pa.ca_city LIKE '%York%'
ORDER BY 
    total_profit DESC NULLS LAST, 
    customer_count DESC;
