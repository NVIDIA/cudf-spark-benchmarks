
WITH RankedCustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        CASE 
            WHEN cs.total_sales IS NULL THEN 'No Sales'
            WHEN cs.total_sales < 1000 THEN 'Low Sales'
            WHEN cs.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Sales'
            ELSE 'High Sales'
        END AS sales_category
    FROM 
        customer c
    JOIN 
        RankedCustomerSales cs ON c.c_customer_id = cs.c_customer_id
    WHERE 
        cs.sales_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.sales_category,
    COALESCE((
        SELECT 
            SUM(sr.sr_return_amt) 
        FROM 
            store_returns sr 
        WHERE 
            sr.sr_customer_sk = c.c_customer_sk
    ), 0) AS total_returns,
    (tc.total_sales - COALESCE((
        SELECT 
            SUM(sr.sr_return_amt) 
        FROM 
            store_returns sr 
        WHERE 
            sr.sr_customer_sk = c.c_customer_sk
    ), 0)) AS net_sales
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
ORDER BY 
    tc.total_sales DESC;
