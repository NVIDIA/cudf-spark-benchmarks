
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.*

    FROM 
        CustomerReturns cr
    JOIN 
        (SELECT 
            sr_cdemo_sk,
            ROW_NUMBER() OVER (ORDER BY COUNT(sr_returned_date_sk) DESC) AS rn
         FROM 
            store_returns
         GROUP BY 
            sr_cdemo_sk
         HAVING 
            COUNT(sr_returned_date_sk) > 0) AS top
    ON cr.sr_customer_sk = top.sr_cdemo_sk
    WHERE 
        rn <= 10
),
Utilization AS (
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_ext_sales_price) AS total_sales,
        COALESCE(MAX(cs_net_profit), 0) AS max_net_profit,
        COALESCE(MIN(cs_net_profit), 0) AS min_net_profit
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(cr.avg_return_quantity, 0) AS avg_return_quantity,
    COALESCE(u.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(u.total_sales, 0) AS total_sales,
    u.max_net_profit,
    u.min_net_profit
FROM 
    customer AS c
LEFT JOIN 
    TopCustomers AS cr ON c.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    Utilization AS u ON c.c_customer_sk = u.customer_sk
WHERE 
    (cr.total_returns IS NOT NULL OR u.total_sales > 1000 OR c.c_birth_year < 1980)
    AND ((c.c_preferred_cust_flag = 'Y' AND cr.total_returns IS NOT NULL) OR cr.total_returns IS NULL)
ORDER BY 
    COALESCE(cr.total_return_amount, 0) DESC, 
    u.total_sales ASC
LIMIT 20;
