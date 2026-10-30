
WITH CustomerAddressCTE AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country,
        ca_address_sk
    FROM 
        customer_address
),
CustomerDemographicsCTE AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_demo_sk
    FROM 
        customer_demographics
),
WebSalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.full_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ws.total_net_profit,
    ws.avg_sales_price,
    ws.total_orders
FROM 
    customer AS c
JOIN 
    CustomerAddressCTE AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    CustomerDemographicsCTE AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    WebSalesCTE AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA'
    AND cd.cd_marital_status = 'M'
    AND (ws.total_net_profit IS NULL OR ws.total_net_profit > 1000)
ORDER BY 
    ws.total_net_profit DESC, 
    c.c_last_name, 
    c.c_first_name;
