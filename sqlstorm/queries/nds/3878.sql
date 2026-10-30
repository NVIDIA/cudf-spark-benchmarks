
WITH RecursiveSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk > 2450000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),

RankedSales AS (
    SELECT 
        rs.c_customer_sk,
        rs.c_first_name,
        rs.c_last_name,
        rs.total_sales,
        COALESCE(cd.cd_gender, 'U') AS gender
    FROM 
        RecursiveSales rs
    LEFT JOIN 
        customer_demographics cd ON rs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        rs.total_sales > 1000
)

SELECT 
    g.gender,
    COUNT(*) AS num_customers,
    AVG(total_sales) AS avg_sales,
    MAX(total_sales) AS max_sales,
    MIN(total_sales) AS min_sales
FROM 
    RankedSales r
JOIN 
    (SELECT DISTINCT gender FROM RankedSales) g ON r.gender = g.gender
GROUP BY 
    g.gender
UNION ALL 
SELECT 
    'Total' AS gender,
    COUNT(*) AS num_customers,
    AVG(total_sales) AS avg_sales,
    MAX(total_sales) AS max_sales,
    MIN(total_sales) AS min_sales
FROM 
    RankedSales
ORDER BY 
    gender;
