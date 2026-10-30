
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_customer_sk
),
WebSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_web_sales_quantity,
        SUM(ws_ext_sales_price) AS total_web_sales_amount
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
SalesComparison AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_return_quantity,
        cr.total_return_amount,
        cr.return_count,
        ws.total_web_sales_quantity,
        ws.total_web_sales_amount
    FROM 
        CustomerReturns cr
    LEFT JOIN 
        WebSales ws ON cr.sr_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(sc.total_return_amount, 0) AS total_return_amount,
    COALESCE(sc.total_web_sales_amount, 0) AS total_web_sales_amount,
    (COALESCE(sc.total_web_sales_amount, 0) - COALESCE(sc.total_return_amount, 0)) AS net_sales,
    sc.return_count
FROM 
    SalesComparison sc
JOIN 
    customer c ON sc.sr_customer_sk = c.c_customer_sk
WHERE 
    sc.return_count > 0
ORDER BY 
    net_sales DESC
LIMIT 10;
