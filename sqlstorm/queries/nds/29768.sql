
WITH AddressDetail AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               NULLIF(ca.ca_suite_number, '') 
               ) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetail AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_net_paid,
        MAX(ws.ws_sold_date_sk) AS last_sold_date
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
ShopReturnDetail AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
CombinedData AS (
    SELECT 
        cd.full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        sd.total_quantity_sold,
        sd.total_net_paid,
        COALESCE(srd.total_returns, 0) AS total_returns
    FROM 
        CustomerDetails cd
    JOIN 
        AddressDetail ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesDetail sd ON cd.c_customer_sk = sd.ws_item_sk -- corrected join condition
    LEFT JOIN 
        ShopReturnDetail srd ON cd.c_customer_sk = srd.sr_customer_sk
)
SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    total_quantity_sold,
    total_net_paid,
    total_returns,
    CASE 
        WHEN total_quantity_sold > 100 THEN 'High Volume Customer' 
        ELSE 'Regular Customer' 
    END AS customer_type
FROM 
    CombinedData
ORDER BY 
    total_net_paid DESC;
