
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_returned_date_sk) AS return_days,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopReturningCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cr.return_days,
        cr.total_return_quantity,
        cr.total_return_amount,
        RANK() OVER (ORDER BY cr.total_return_amount DESC) AS rank
    FROM 
        CustomerReturns cr
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
                              AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(t.return_days, 0) AS return_days,
    COALESCE(t.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(t.total_return_amount, 0) AS total_return_amount,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.net_profit, 0) AS net_profit,
    CASE 
        WHEN t.rank IS NOT NULL AND s.total_sales > 0 THEN 'VIP'
        WHEN t.return_days > 3 OR t.total_return_quantity > 5 THEN 'Frequent Returner'
        ELSE 'Normal'
    END AS customer_category
FROM 
    customer c
LEFT JOIN 
    TopReturningCustomers t ON c.c_customer_sk = t.sr_customer_sk
LEFT JOIN 
    SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    c.c_birth_year < 1990 AND 
    c.c_current_cdemo_sk IS NOT NULL
ORDER BY 
    total_return_amount DESC, total_sales DESC;
