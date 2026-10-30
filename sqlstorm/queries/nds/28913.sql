
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_dep_count) AS avg_dep_count
    FROM 
        customer 
    JOIN 
        customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesInfo AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.full_address,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count,
    ds.avg_dep_count,
    si.total_sales,
    si.order_count
FROM 
    AddressDetails ad
LEFT JOIN 
    SalesInfo si ON ad.ca_address_sk = si.ws_bill_addr_sk
LEFT JOIN 
    DemographicSummary ds ON ad.ca_state = (CASE WHEN ds.cd_gender = 'M' THEN 'NY' ELSE 'CA' END)
WHERE 
    ad.ca_city IS NOT NULL AND 
    si.total_sales > 1000
ORDER BY 
    total_sales DESC, 
    ad.ca_city;
