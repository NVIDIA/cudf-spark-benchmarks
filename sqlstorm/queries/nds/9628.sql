
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND cd.cd_purchase_estimate > 1000
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
SalesRanked AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    sr.cd_gender,
    AVG(sr.total_sales) AS avg_sales,
    AVG(sr.order_count) AS avg_order_count
FROM 
    SalesRanked sr
WHERE 
    sr.sales_rank <= 10
GROUP BY 
    sr.cd_gender
ORDER BY 
    sr.cd_gender;
