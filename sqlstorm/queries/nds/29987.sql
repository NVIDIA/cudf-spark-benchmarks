
WITH AddressSummary AS (
    SELECT 
        ca_country,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM 
        customer_address
    WHERE 
        ca_city LIKE 'San%'
    GROUP BY 
        ca_country
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        w_city,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    JOIN 
        warehouse ON ws_warehouse_sk = w_warehouse_sk
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w_city
)
SELECT 
    A.ca_country,
    A.unique_addresses,
    A.avg_gmt_offset,
    D.cd_gender,
    D.total_customers,
    D.avg_dependents,
    S.w_city,
    S.total_sales,
    S.total_orders
FROM 
    AddressSummary A
JOIN 
    DemographicSummary D ON D.total_customers > 100
JOIN 
    SalesSummary S ON S.total_sales > 10000
ORDER BY 
    A.unique_addresses DESC, 
    S.total_sales DESC;
