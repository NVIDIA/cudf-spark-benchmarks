
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        COUNT(*) AS return_count, 
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesStats AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales_price,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales ws 
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 10000 
    GROUP BY 
        c.c_customer_sk
),
ReturnRatio AS (
    SELECT 
        cs.return_count,
        ss.total_sales_price,
        ss.total_orders,
        ss.total_quantity,
        COALESCE(cs.return_count, 0) * 1.0 / NULLIF(ss.total_orders, 0) AS return_ratio
    FROM 
        CustomerReturns cs
    FULL OUTER JOIN 
        SalesStats ss ON cs.sr_customer_sk = ss.c_customer_sk
)
SELECT 
    r.return_count,
    r.total_sales_price,
    r.total_orders,
    r.total_quantity,
    r.return_ratio,
    CASE 
        WHEN r.return_ratio IS NULL THEN 'No Sales'
        WHEN r.return_ratio < 0.1 THEN 'Low Returns'
        WHEN r.return_ratio < 0.25 THEN 'Moderate Returns'
        ELSE 'High Returns'
    END AS return_category
FROM 
    ReturnRatio r
WHERE 
    r.return_count > 0 OR r.total_orders > 0
ORDER BY 
    r.return_ratio DESC, r.total_sales_price DESC
LIMIT 20;
