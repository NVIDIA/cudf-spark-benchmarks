
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value,
        COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_pages_viewed
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (
            SELECT MAX(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq = 1
        ) AND (
            SELECT MAX(d.d_date_sk)
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq = 12
        )
    GROUP BY 
        c.c_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        MAX(cd.cd_marital_status) AS marital_status,
        MAX(cd.cd_gender) AS gender,
        COUNT(DISTINCT cd.cd_demo_sk) AS demographics_count
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_sales,
    cs.order_count,
    cs.avg_order_value,
    cs.distinct_pages_viewed,
    cd.marital_status,
    cd.gender
FROM 
    CustomerSales cs
JOIN 
    CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    cs.total_sales > 1000
ORDER BY 
    cs.total_sales DESC
LIMIT 50;
