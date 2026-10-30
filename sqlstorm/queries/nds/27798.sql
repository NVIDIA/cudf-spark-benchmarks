
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(COALESCE(ca_street_number, ''), ' ', COALESCE(ca_street_name, ''), ' ', COALESCE(ca_street_type, ''), 
               COALESCE(ca_suite_number, ''), ', ', COALESCE(ca_city, ''), ', ', COALESCE(ca_state, ''), ' ', COALESCE(ca_zip, ''), 
               ', ', COALESCE(ca_country, '')) AS full_address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(COALESCE(c_salutation, ''), ' ', COALESCE(c_first_name, ''), ' ', COALESCE(c_last_name, '')) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
),
CompositeAddress AS (
    SELECT 
        cad.ca_address_sk,
        COUNT(DISTINCT cus.c_customer_sk) AS customer_count,
        MIN(COALESCE(cus.full_name, 'Unknown')) AS representative_name,
        MIN(cus.cd_gender) AS representative_gender,
        MIN(cus.cd_marital_status) AS representative_marital_status,
        MIN(cus.cd_credit_rating) AS representative_credit_rating,
        SUM(COALESCE(s.total_sales, 0)) AS total_sales,
        SUM(COALESCE(s.total_profit, 0)) AS total_profit,
        AVG(COALESCE(s.unique_items_sold, 0)) AS avg_unique_items
    FROM 
        AddressDetails cad
    LEFT JOIN 
        CustomerDetails cus ON cad.ca_address_sk = cus.c_customer_sk  
    LEFT JOIN 
        SalesData s ON s.ws_order_number = cad.ca_address_sk  
    GROUP BY 
        cad.ca_address_sk
)
SELECT 
    ca.ca_address_sk,
    ad.full_address,
    ca.customer_count,
    ca.representative_name,
    ca.representative_gender,
    ca.representative_marital_status,
    ca.representative_credit_rating,
    COALESCE(ca.total_sales, 0) AS total_sales,
    COALESCE(ca.total_profit, 0) AS total_profit,
    COALESCE(ca.avg_unique_items, 0) AS avg_unique_items
FROM 
    CompositeAddress ca
JOIN 
    AddressDetails ad ON ca.ca_address_sk = ad.ca_address_sk
ORDER BY 
    ca.total_sales DESC
LIMIT 100;
