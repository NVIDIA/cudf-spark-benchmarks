
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
DemographicAnalysis AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(cs.c_customer_sk) AS customer_count,
        AVG(cs.total_sales) AS avg_sales,
        SUM(cs.total_orders) AS total_orders
    FROM 
        customer_demographics cd
    JOIN 
        CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    COUNT(*) AS demographic_count,
    SUM(da.avg_sales) AS total_sales_avg,
    SUM(da.total_orders) AS total_order_count
FROM 
    DemographicAnalysis da
GROUP BY 
    da.cd_gender, da.cd_marital_status
HAVING 
    COUNT(*) > 100
ORDER BY 
    total_sales_avg DESC;
