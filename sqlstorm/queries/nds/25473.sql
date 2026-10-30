
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
Demographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status,
        CONCAT(cd_gender, ' - ', cd_marital_status) AS gender_marital,
        CASE 
            WHEN cd_purchase_estimate > 1000 THEN 'HIGH'
            WHEN cd_purchase_estimate > 500 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS purchase_estimate_category
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        COUNT(ws_item_sk) AS total_items_sold,
        SUM(ws_sales_price) AS total_sales_amount,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ad.full_address,
        d.gender_marital,
        sd.total_items_sold,
        sd.total_sales_amount,
        sd.avg_sales_price,
        d.purchase_estimate_category
    FROM 
        customer c
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    c_first_name, 
    c_last_name, 
    full_address, 
    gender_marital, 
    total_items_sold, 
    total_sales_amount, 
    avg_sales_price
FROM 
    CombinedData
WHERE 
    purchase_estimate_category = 'HIGH'
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
