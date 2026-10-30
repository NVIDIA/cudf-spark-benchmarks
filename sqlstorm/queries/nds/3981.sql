
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
DemographicInfo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
SalesRanking AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.avg_net_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    sr.sales_rank,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.avg_net_profit,
    di.customer_count,
    COALESCE(di.cd_gender, 'Not Specified') AS gender,
    COALESCE(di.cd_marital_status, 'Not Specified') AS marital_status
FROM 
    SalesRanking sr
JOIN 
    CustomerSales cs ON sr.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    DemographicInfo di ON cs.c_customer_sk = di.cd_demo_sk
WHERE 
    cs.total_sales > 1000
    AND di.customer_count IS NOT NULL
ORDER BY 
    sr.sales_rank;
