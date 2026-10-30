
WITH  SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag 
),
FilteredSales AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_profit,
        CASE 
            WHEN sh.total_profit > 1000 THEN 'High'
            WHEN sh.total_profit BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM 
        SalesHierarchy sh
    WHERE 
        sh.rn = 1
),
RankedSales AS (
    SELECT 
        fs.*,
        RANK() OVER (ORDER BY fs.total_profit DESC) AS sales_rank
    FROM 
        FilteredSales fs
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.profit_category,
    f.total_profit
FROM 
    RankedSales f
JOIN 
    customer_demographics cd ON f.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
    AND cd.cd_dep_count IS NOT NULL
    AND f.total_profit > 200
UNION ALL
SELECT 
    'Overall Total' AS c_first_name,
    NULL AS c_last_name,
    NULL AS profit_category,
    SUM(total_profit) AS total_profit
FROM 
    RankedSales
WHERE 
    profit_category IS NOT NULL
GROUP BY profit_category
ORDER BY 
    total_profit DESC;
