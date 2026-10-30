
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_state) AS city_rank
    FROM 
        customer_address ca
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    rc.customer_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    rc.cd_purchase_estimate,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country,
    ss.total_sales,
    ss.order_count
FROM 
    RankedCustomers rc
JOIN 
    AddressInfo ai ON rc.c_customer_sk = ai.ca_address_sk
JOIN 
    SalesSummary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    rc.rank <= 5 AND ai.city_rank <= 10
ORDER BY 
    rc.cd_gender, ss.total_sales DESC;
