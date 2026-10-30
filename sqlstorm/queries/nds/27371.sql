
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
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
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        rc.full_name,
        rc.cd_gender
    FROM 
        customer_address ca
    JOIN 
        RankedCustomers rc ON ca.ca_address_sk = rc.c_customer_sk
    WHERE 
        rc.rank <= 10
),
SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
FinalReport AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country,
        ca.full_name, 
        ca.cd_gender, 
        ss.total_sales_price,
        ss.order_count
    FROM 
        CustomerAddresses ca
    LEFT JOIN 
        SalesSummary ss ON ca.ca_address_sk = ss.ws_item_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    cd_gender,
    total_sales_price,
    order_count
FROM 
    FinalReport
WHERE 
    total_sales_price IS NOT NULL
ORDER BY 
    total_sales_price DESC;
