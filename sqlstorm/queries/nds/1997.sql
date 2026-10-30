
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returned_quantity,
        cr.total_return_amount,
        DENSE_RANK() OVER (ORDER BY cr.total_return_amount DESC) AS rank
    FROM 
        customer AS c
    JOIN 
        CustomerReturns AS cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.total_returned_quantity > 0
),
ActiveCustomers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returned_quantity,
    tc.total_return_amount,
    ac.total_orders,
    ac.total_sales,
    CASE 
        WHEN ac.total_sales IS NOT NULL THEN ROUND((tc.total_return_amount / ac.total_sales) * 100, 2)
        ELSE NULL
    END AS return_percentage
FROM 
    TopCustomers AS tc
LEFT JOIN 
    ActiveCustomers AS ac ON tc.c_customer_sk = ac.c_customer_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    return_percentage DESC NULLS LAST;
