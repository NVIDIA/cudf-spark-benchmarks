
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        hd.hd_income_band_sk,
        COUNT(cd.cd_demo_sk) AS demo_count,
        AVG(hd.hd_dep_count) AS avg_dep_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, hd.hd_income_band_sk
)
SELECT 
    ca.ca_city,
    SUM(cs.total_sales) AS total_city_sales,
    AVG(dm.avg_dep_count) AS avg_dependencies,
    CASE 
        WHEN SUM(cs.total_sales) IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    customer_address ca
LEFT JOIN 
    customer_sales cs ON cs.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    demographics dm ON dm.hd_income_band_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(cs.total_sales) > 0 OR AVG(dm.avg_dep_count) > 1
ORDER BY 
    total_city_sales DESC;
