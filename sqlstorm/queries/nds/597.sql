
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_bill_customer_sk, 
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_bill_customer_sk
),
DateRange AS (
    SELECT 
        d_date_sk, 
        d_date
    FROM 
        date_dim
    WHERE 
        d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
DetailedSummary AS (
    SELECT 
        dr.d_date_sk,
        dr.d_date,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(ws.total_orders, 0) AS total_orders,
        COALESCE(ws.total_sales, 0) AS total_sales
    FROM 
        DateRange dr
    LEFT JOIN 
        CustomerReturns cr 
        ON dr.d_date_sk = cr.sr_returned_date_sk
    LEFT JOIN 
        WebSalesSummary ws 
        ON dr.d_date_sk = ws.ws_sold_date_sk
)
SELECT 
    ds.d_date,
    ds.total_orders,
    ds.total_sales,
    ds.total_return_quantity,
    (ds.total_sales - ds.total_return_quantity) AS net_sales,
    CASE 
        WHEN ds.total_orders = 0 THEN NULL
        ELSE (ds.total_sales / NULLIF(ds.total_orders, 0))
    END AS average_order_value
FROM 
    DetailedSummary ds
ORDER BY 
    ds.d_date;
