
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
WebSalesAggregate AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        wsa.total_net_paid,
        wsa.total_orders
    FROM 
        CustomerInfo AS ci
    LEFT JOIN 
        WebSalesAggregate AS wsa ON ci.c_customer_sk = wsa.ws_bill_customer_sk
)
SELECT 
    *, 
    CASE 
        WHEN total_net_paid IS NULL THEN 'No Sales'
        WHEN total_net_paid < 100 THEN 'Low Value Customer'
        WHEN total_net_paid >= 100 AND total_net_paid < 1000 THEN 'Medium Value Customer'
        ELSE 'High Value Customer'
    END AS customer_value_category
FROM 
    FinalReport
ORDER BY 
    total_net_paid DESC;
