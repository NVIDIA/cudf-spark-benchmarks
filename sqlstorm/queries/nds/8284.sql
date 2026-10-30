
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SalesSummary AS (
    SELECT 
        cd.cd_gender,
        COUNT(cs.c_customer_sk) AS customer_count,
        SUM(cs.total_sales) AS total_sales_amount,
        AVG(cs.total_sales) AS average_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
SalesRanking AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales_amount DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    sr.cd_gender,
    sr.customer_count,
    sr.total_sales_amount,
    sr.average_sales,
    sr.sales_rank
FROM 
    SalesRanking sr
WHERE 
    sr.sales_rank <= 5
ORDER BY 
    sr.total_sales_amount DESC;
