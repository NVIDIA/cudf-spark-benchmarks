
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesAggregation AS (
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
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    sa.total_orders,
    sa.total_profit
FROM 
    CustomerDetails cd
LEFT JOIN 
    AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
LEFT JOIN 
    SalesAggregation sa ON cd.c_customer_sk = sa.ws_bill_customer_sk
WHERE 
    cd.cd_marital_status = 'M' AND 
    sa.total_profit > 1000 
ORDER BY 
    sa.total_profit DESC;
