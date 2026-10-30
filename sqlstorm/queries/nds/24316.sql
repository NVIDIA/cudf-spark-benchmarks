
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_moy IN (SELECT DISTINCT d_moy FROM date_dim WHERE d_moy BETWEEN 1 AND 6)
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_date
    HAVING 
        SUM(ws_ext_sales_price) > 1000
),
ReturnThreshold AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(r.total_returns), 0) AS total_returns_count
    FROM 
        customer c
    LEFT JOIN RankedReturns r ON c.c_customer_sk = r.sr_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    HVC.c_customer_id,
    HVC.c_first_name,
    HVC.c_last_name,
    CASE 
        WHEN RT.total_returns_count = 0 THEN 'No returns'
        WHEN RT.total_returns_count > 10 THEN 'Frequent returner'
        ELSE 'Occasional returner'
    END AS return_behavior,
    HVC.order_count,
    HVC.total_sales
FROM 
    HighValueCustomers HVC
JOIN 
    ReturnThreshold RT ON HVC.c_customer_id = RT.c_customer_id
WHERE 
    (HVC.total_sales > 5000 OR RT.total_returns_count = 0) 
    AND HVC.c_last_name IS NOT NULL
ORDER BY 
    HVC.total_sales DESC, 
    HVC.c_last_name ASC
LIMIT 100;
