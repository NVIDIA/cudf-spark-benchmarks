
WITH  SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS Total_Sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS SalesRank
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        Total_Sales,
        SalesRank
    FROM 
        SalesHierarchy AS c
    WHERE 
        SalesRank <= 10
),
CustomerCounts AS (
    SELECT 
        cd.cd_gender, 
        COUNT(DISTINCT c.c_customer_sk) AS NumberOfCustomers,
        AVG(hd.hd_dep_count) AS AverageDependents
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    LEFT JOIN 
        household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    rs.c_first_name,
    rs.c_last_name,
    rs.Total_Sales,
    cc.cd_gender,
    cc.NumberOfCustomers,
    cc.AverageDependents
FROM 
    RankedSales AS rs
LEFT JOIN 
    CustomerCounts AS cc ON cc.cd_gender IS NOT NULL
ORDER BY 
    rs.Total_Sales DESC
LIMIT 20;
