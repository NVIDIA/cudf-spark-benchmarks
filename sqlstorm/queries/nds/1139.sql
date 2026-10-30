
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_dense_rank,
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ws.ws_order_number, ws.ws_bill_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
SalesWithDemographics AS (
    SELECT 
        cs.ws_order_number,
        cs.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cs.sales_rank = 1 THEN 'Top Sales'
            WHEN cs.sales_rank <= 5 THEN 'Top 5 Sales'
            ELSE 'Other Sales'
        END AS sales_category
    FROM 
        RankedSales cs
    LEFT JOIN 
        CustomerDemographics cd ON cs.ws_bill_customer_sk = cd.cd_demo_sk
)
SELECT 
    swd.sales_category,
    swd.cd_gender,
    swd.cd_marital_status,
    COUNT(swd.ws_order_number) AS order_count,
    AVG(swd.total_sales) AS avg_sales,
    SUM(swd.total_sales) AS total_revenue
FROM 
    SalesWithDemographics swd
WHERE 
    swd.total_sales IS NOT NULL
GROUP BY 
    swd.sales_category, swd.cd_gender, swd.cd_marital_status
ORDER BY 
    total_revenue DESC
LIMIT 10;
