
WITH AddressDetails AS (
    SELECT 
        ca_county,
        CONCAT(ca_city, ', ', ca_zip) AS address_info,
        CA_GMT_Offset,
        COUNT(*) AS address_count
    FROM 
        customer_address 
    GROUP BY 
        ca_county, ca_city, ca_zip, CA_GMT_Offset
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT 
        'web' AS sales_channel,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        sales_channel
    UNION ALL
    SELECT 
        'catalog' AS sales_channel,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM 
        catalog_sales
    GROUP BY 
        sales_channel
    UNION ALL
    SELECT 
        'store' AS sales_channel,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_orders
    FROM 
        store_sales
    GROUP BY 
        sales_channel
)
SELECT 
    a.ca_county,
    a.address_info,
    a.ca_gmt_offset,
    d.cd_gender,
    d.cd_marital_status,
    d.total_purchase_estimate,
    s.sales_channel,
    s.total_sales,
    s.total_orders
FROM 
    AddressDetails a
JOIN 
    Demographics d ON a.address_count > 10  
JOIN 
    SalesSummary s ON s.total_sales > 10000  
ORDER BY 
    a.ca_county, s.total_sales DESC
LIMIT 100;
