
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM
        store_returns
    WHERE
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        sr_item_sk
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c_customer_sk
    HAVING 
        SUM(ws_net_paid) > 1000
),
FinalMetrics AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        hv.total_spent
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns cr ON r.ws_item_sk = cr.sr_item_sk
    LEFT JOIN 
        HighValueCustomers hv ON hv.c_customer_sk IN (
            SELECT DISTINCT ws_bill_customer_sk 
            FROM web_sales 
            WHERE ws_item_sk = r.ws_item_sk
        )
)
SELECT
    fm.ws_item_sk,
    fm.total_quantity,
    fm.total_sales,
    fm.total_returns,
    fm.total_return_amt,
    CASE 
        WHEN fm.total_sales = 0 THEN 'No Sales'
        WHEN fm.total_returns > fm.total_quantity THEN 'Over Returned'
        ELSE 'Normal'
    END AS sale_status,
    CASE 
        WHEN fm.total_spent IS NULL THEN 'No High Value Customers'
        ELSE 'Has High Value Customers'
    END AS customer_status
FROM 
    FinalMetrics fm
WHERE 
    fm.total_sales > 1000
    OR fm.total_returns > 10
ORDER BY 
    fm.total_sales DESC, 
    fm.total_quantity ASC;
