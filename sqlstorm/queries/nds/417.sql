
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(sr_return_quantity) AS total_returned_items
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CombinedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        COALESCE(sr.total_return_amt, 0) AS total_return_amt,
        cs.total_orders,
        cs.avg_net_profit,
        CASE 
            WHEN sr.total_returned_items IS NOT NULL 
            THEN 'Returned' 
            ELSE 'Not Returned' 
        END AS return_status
    FROM 
        CustomerSales cs
    LEFT JOIN 
        StoreReturns sr ON cs.c_customer_sk = sr.sr_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_web_sales,
    cs.total_return_amt,
    cs.total_orders,
    cs.avg_net_profit,
    cs.return_status,
    ROW_NUMBER() OVER (PARTITION BY cs.return_status ORDER BY cs.total_web_sales DESC) AS rank
FROM 
    CombinedSales cs
WHERE 
    cs.total_web_sales > 5000
ORDER BY 
    cs.return_status, cs.total_web_sales DESC
LIMIT 10;
