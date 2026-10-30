
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_net_paid, 0)) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status
),
AggregateSales AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(total_web_sales) AS avg_web_sales,
        AVG(total_catalog_sales) AS avg_catalog_sales,
        SUM(total_web_orders) AS total_web_orders,
        SUM(total_catalog_orders) AS total_catalog_orders
    FROM CustomerSales
    GROUP BY 
        cd_gender, 
        cd_marital_status
),
TopSales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY avg_web_sales DESC) AS rn_web,
        ROW_NUMBER() OVER (ORDER BY avg_catalog_sales DESC) AS rn_catalog
    FROM AggregateSales
)
SELECT 
    cd_gender,
    cd_marital_status,
    avg_web_sales,
    avg_catalog_sales,
    total_web_orders,
    total_catalog_orders
FROM TopSales
WHERE rn_web <= 5 OR rn_catalog <= 5
ORDER BY cd_gender, cd_marital_status;
