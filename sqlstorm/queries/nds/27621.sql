
WITH AddressConcatenation AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerWithDemographics AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_purchase_estimate,
    a.full_address,
    COALESCE(s.total_profit, 0) AS total_profit,
    s.total_orders
FROM 
    CustomerWithDemographics c
LEFT JOIN 
    AddressConcatenation a ON c.c_customer_sk = a.ca_address_sk
LEFT JOIN 
    SalesSummary s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    c.cd_purchase_estimate > 0
ORDER BY 
    total_profit DESC, 
    c.full_name ASC;
