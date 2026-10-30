WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk
),
AverageSale AS (
    SELECT
        AVG(total_web_sales) AS avg_web_sales,
        AVG(total_store_sales) AS avg_store_sales
    FROM 
        CustomerSales
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.total_web_sales) AS gender_web_sales,
        SUM(cs.total_store_sales) AS gender_store_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    d.d_day_name,
    COUNT(DISTINCT ws.ws_order_number) AS orders_today,
    SUM(ws.ws_net_profit) AS total_profit_today,
    COALESCE(sbd.gender_web_sales, 0) AS web_sales_by_gender,
    COALESCE(sbd.gender_store_sales, 0) AS store_sales_by_gender,
    (SELECT avg_web_sales FROM AverageSale) AS avg_web_sales,
    (SELECT avg_store_sales FROM AverageSale) AS avg_store_sales
FROM 
    date_dim d
LEFT JOIN 
    web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN 
    SalesByDemographics sbd ON 1=1 
WHERE 
    d.d_date = cast('2002-10-01' as date)
AND 
    (sbd.gender_web_sales > (SELECT avg_web_sales FROM AverageSale) OR sbd.gender_store_sales > (SELECT avg_store_sales FROM AverageSale))
GROUP BY 
    d.d_day_name, sbd.gender_web_sales, sbd.gender_store_sales
ORDER BY 
    d.d_day_name;