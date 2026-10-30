
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        CASE 
            WHEN total_web_profit > total_catalog_profit AND total_web_profit > total_store_profit THEN 'Web Sales' 
            WHEN total_catalog_profit > total_web_profit AND total_catalog_profit > total_store_profit THEN 'Catalog Sales' 
            ELSE 'Store Sales' 
        END AS highest_channel,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(total_web_profit + total_catalog_profit + total_store_profit) AS total_sales
    FROM 
        CustomerSales c
    JOIN 
        Demographics d ON c.c_customer_sk = d.customer_count
    GROUP BY 
        highest_channel
)
SELECT 
    highest_channel,
    customer_count,
    total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM 
    SalesSummary
ORDER BY 
    sales_rank
LIMIT 10;
