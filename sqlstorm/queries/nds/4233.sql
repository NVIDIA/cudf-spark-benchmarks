
WITH RankedReturns AS (
    SELECT 
        cr_returning_customer_sk,
        cr_item_sk,
        cr_return_quantity,
        cr_return_amount,
        ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY cr_return_amount DESC) AS rn
    FROM 
        catalog_returns
    WHERE 
        cr_return_quantity > 0
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cr.cr_item_sk) AS return_count,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        RankedReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
TopReturningCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.return_count,
        cs.total_return_amount,
        DENSE_RANK() OVER (ORDER BY cs.total_return_amount DESC) AS rank
    FROM 
        CustomerStats cs
), 
TotalSales AS (
    SELECT 
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
)

SELECT 
    trc.c_customer_sk,
    trc.return_count,
    trc.total_return_amount,
    ts.total_sales,
    CASE 
        WHEN ts.total_sales = 0 THEN NULL
        ELSE round((trc.total_return_amount / ts.total_sales) * 100, 2)
    END AS return_percentage
FROM 
    TopReturningCustomers trc
CROSS JOIN 
    TotalSales ts
WHERE 
    trc.rank <= 10
ORDER BY 
    trc.total_return_amount DESC;
