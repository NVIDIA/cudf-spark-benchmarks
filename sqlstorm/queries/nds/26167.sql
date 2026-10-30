
WITH CustomerInfo AS (
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
), SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
), FinalReport AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        si.total_profit,
        si.total_orders,
        si.unique_items_sold
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
    WHERE 
        ci.ca_state IN ('CA', 'NY', 'TX') 
        AND si.total_profit IS NOT NULL
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_profit,
    total_orders,
    unique_items_sold,
    ROUND(total_profit / NULLIF(total_orders, 0), 2) AS avg_profit_per_order
FROM 
    FinalReport
ORDER BY 
    total_profit DESC
LIMIT 100;
