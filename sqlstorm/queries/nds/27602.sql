
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
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
),
CustomerDetails AS (
    SELECT 
        rc.c_customer_sk,
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        ss.total_profit,
        ss.total_orders,
        rc.gender_rank
    FROM 
        RankedCustomers rc
    JOIN 
        AddressDetails ad ON rc.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesSummary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    cd.*,
    CASE 
        WHEN cd.total_profit IS NULL THEN 'No Orders'
        WHEN cd.total_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM 
    CustomerDetails cd
WHERE 
    cd.gender_rank = 1
ORDER BY 
    cd.total_profit DESC
LIMIT 100;
