
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
SalesByShippingMethod AS (
    SELECT 
        sm.sm_type,
        SUM(ws.ws_net_paid) AS total_sales_by_method
    FROM 
        web_sales AS ws
    JOIN 
        ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_type
),
SalesWithDemographics AS (
    SELECT 
        cd.cd_gender,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales
    FROM 
        customer_demographics AS cd
    LEFT JOIN 
        catalog_sales AS cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    LEFT JOIN 
        web_sales AS ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.total_orders,
    sbs.total_sales_by_method,
    sdb.total_catalog_sales,
    sdb.total_web_sales
FROM 
    CustomerSales AS cs
JOIN 
    SalesByShippingMethod AS sbs ON cs.total_sales > 1000
JOIN 
    SalesWithDemographics AS sdb ON cs.total_sales < 5000
ORDER BY 
    cs.total_sales DESC
LIMIT 100;
