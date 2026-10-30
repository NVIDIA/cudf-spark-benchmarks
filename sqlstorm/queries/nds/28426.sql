
WITH AddressCount AS (
    SELECT 
        ca_city,
        COUNT(ca_address_sk) AS total_address_count
    FROM 
        customer_address 
    GROUP BY 
        ca_city
), 
CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
), 
SalesSummary AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    ac.ca_city,
    ac.total_address_count,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_customers,
    cs.avg_purchase_estimate,
    ss.d_year,
    ss.total_sales,
    ss.total_quantity
FROM 
    AddressCount AS ac
JOIN 
    CustomerStats AS cs ON cs.total_customers > 0
JOIN 
    SalesSummary AS ss ON ss.total_sales > 0
ORDER BY 
    ac.total_address_count DESC, 
    cs.total_customers DESC, 
    ss.total_sales DESC
LIMIT 100;
