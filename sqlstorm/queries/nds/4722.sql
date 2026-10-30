
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
),
SalesRatio AS (
    SELECT 
        a.sr_customer_sk,
        COALESCE(b.total_sales, 0) AS total_sales,
        COALESCE(a.total_returns, 0) AS total_returns,
        CASE 
            WHEN COALESCE(b.total_sales, 0) > 0 THEN 
                ROUND(COALESCE(a.total_returns, 0) * 100.0 / b.total_sales, 2)
            ELSE 
                NULL 
        END AS return_ratio
    FROM 
        CustomerReturns a
    LEFT JOIN 
        WebSalesSummary b ON a.sr_customer_sk = b.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.return_ratio,
    CASE 
        WHEN s.return_ratio > 10 THEN 'High Return Customer'
        WHEN s.return_ratio BETWEEN 5 AND 10 THEN 'Moderate Return Customer'
        ELSE 'Low Return Customer'
    END AS return_customer_type
FROM 
    SalesRatio s
JOIN 
    customer c ON s.sr_customer_sk = c.c_customer_sk
ORDER BY 
    s.return_ratio DESC NULLS LAST;
