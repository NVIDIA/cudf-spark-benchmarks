WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk, sr_item_sk
),
HighReturnCustomers AS (
    SELECT 
        rr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        COUNT(rr.sr_item_sk) AS item_return_count,
        SUM(rr.total_returned) AS total_returned_quantity
    FROM 
        RankedReturns rr
    JOIN 
        customer c ON rr.sr_customer_sk = c.c_customer_sk
    WHERE 
        rr.return_rank <= 3
    GROUP BY 
        rr.sr_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
),
DailySales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
),
SalesReturnRatio AS (
    SELECT 
        d.d_date,
        ds.total_sales,
        COALESCE(SUM(sr.total_returned), 0) AS total_returns,
        CASE 
            WHEN ds.total_sales > 0 THEN (COALESCE(SUM(sr.total_returned), 0) * 1.0 / ds.total_sales) 
            ELSE NULL 
        END AS return_ratio
    FROM 
        DailySales ds
    LEFT JOIN 
        RankedReturns sr ON sr.sr_customer_sk IN (SELECT sr_customer_sk FROM HighReturnCustomers)
    JOIN 
        date_dim d ON ds.d_date = d.d_date
    GROUP BY 
        d.d_date, ds.total_sales
)
SELECT 
    hrc.sr_customer_sk,
    hrc.c_first_name,
    hrc.c_last_name,
    hrc.c_email_address,
    d.d_date,
    d.total_sales,
    d.total_returns,
    d.return_ratio,
    ROW_NUMBER() OVER (PARTITION BY hrc.sr_customer_sk ORDER BY d.d_date DESC) AS recent_purchase_rank
FROM 
    HighReturnCustomers hrc
JOIN 
    SalesReturnRatio d ON d.d_date = cast('2002-10-01' as date) - INTERVAL '1 DAY' 
WHERE 
    d.return_ratio IS NOT NULL AND
    d.return_ratio > 0.1
ORDER BY 
    hrc.sr_customer_sk, d.d_date;