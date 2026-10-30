
WITH AddressSummary AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        full_address
),
CustomerDemoSummary AS (
    SELECT 
        cd_gender,
        CD_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT 
        d.d_year,
        s.s_store_name,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    JOIN 
        date_dim d ON ws_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON s.s_store_sk = ws_warehouse_sk
    GROUP BY 
        d.d_year, s.s_store_name
)
SELECT 
    a.full_address,
    a.address_count,
    c.cd_gender,
    c.cd_marital_status,
    c.avg_purchase_estimate,
    s.d_year,
    s.s_store_name,
    s.total_sales,
    s.order_count
FROM 
    AddressSummary a
JOIN 
    CustomerDemoSummary c ON c.customer_count > 10
JOIN 
    SalesSummary s ON s.total_sales > 10000
ORDER BY 
    a.address_count DESC, s.total_sales DESC;
