
WITH AddressInfo AS (
    SELECT 
        ca_city AS city, 
        ca_state AS state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_country AS country,
        ca_address_sk
    FROM 
        customer_address
    WHERE 
        ca_country LIKE '%United%'
),
DemographicInfo AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate, 
        CASE 
            WHEN cd_purchase_estimate < 500 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 500 AND 1500 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category,
        cd_demo_sk
    FROM 
        customer_demographics
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk, 
        COUNT(ws_order_number) AS total_orders, 
        SUM(ws_net_profit) AS total_profit, 
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ai.city,
    ai.state,
    ai.full_address,
    ai.country,
    di.cd_gender,
    di.cd_marital_status,
    di.cd_education_status,
    di.purchase_category,
    ws.total_orders,
    ws.total_profit,
    ws.total_quantity
FROM 
    AddressInfo ai
JOIN 
    customer c ON ai.ca_address_sk = c.c_current_addr_sk
JOIN 
    DemographicInfo di ON c.c_current_cdemo_sk = di.cd_demo_sk
LEFT JOIN 
    WebSalesSummary ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ai.state IN ('CA', 'NY') 
ORDER BY 
    ws.total_profit DESC
LIMIT 100;
