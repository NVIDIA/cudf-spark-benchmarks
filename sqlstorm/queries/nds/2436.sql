
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        cr.total_return_quantity,
        RANK() OVER (ORDER BY cr.total_return_amount DESC) AS rk
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.sr_customer_sk = c.c_customer_sk
),
DateSales AS (
    SELECT
        d.d_date,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_date
),
AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM 
        DateSales
),
SalesComparative AS (
    SELECT
        ds.d_date,
        ds.total_sales,
        CASE
            WHEN ds.total_sales > (SELECT avg_sales FROM AverageSales) THEN 'Above Average'
            ELSE 'Below Average'
        END AS sales_category
    FROM 
        DateSales ds
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    sc.d_date,
    sc.total_sales,
    sc.sales_category,
    COALESCE(tc.total_returns, 0) AS total_returns,
    COALESCE(tc.total_return_amount, 0) AS total_return_amount,
    DENSE_RANK() OVER (PARTITION BY sc.d_date ORDER BY sc.total_sales DESC) AS sales_rank
FROM 
    SalesComparative sc
LEFT JOIN 
    TopCustomers tc ON tc.rk <= 10
ORDER BY 
    sc.d_date, sales_rank;
