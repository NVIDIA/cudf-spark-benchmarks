
WITH RecursiveSales AS (
    SELECT 
        s_store_id,
        ss_sold_date_sk,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales 
    JOIN 
        store ON store.s_store_sk = store_sales.ss_store_sk
    GROUP BY 
        s_store_id, ss_sold_date_sk
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(cr.total_returns), 0) AS returns_count,
        COALESCE(SUM(cr.total_returned_amount), 0) AS returned_amount
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        c.c_birth_year = (SELECT MAX(c2.c_birth_year) FROM customer c2 WHERE c2.c_preferred_cust_flag = 'Y')
    GROUP BY 
        c.c_customer_id
),
SalesVolatility AS (
    SELECT 
        s_store_id,
        AVG(total_sales) AS avg_sales,
        STDDEV(total_sales) AS sales_std_dev,
        CASE
            WHEN AVG(total_sales) IS NULL THEN 'No Sales'
            WHEN STDDEV(total_sales) > (0.1 * AVG(total_sales)) THEN 'High volatility'
            ELSE 'Stable'
        END AS volatility_status
    FROM 
        RecursiveSales
    GROUP BY 
        s_store_id
)
SELECT 
    t0.s_store_id,
    t1.c_customer_id,
    t1.returns_count,
    t1.returned_amount,
    t2.avg_sales,
    t2.sales_std_dev,
    t2.volatility_status
FROM 
    store t0
JOIN 
    TopCustomers t1 ON t1.returns_count > (SELECT AVG(returns_count) FROM TopCustomers)
JOIN 
    SalesVolatility t2 ON t2.s_store_id = t0.s_store_id
WHERE 
    (t1.returned_amount IS NOT NULL OR t1.returned_amount <> 0)
    AND t2.volatility_status = 'High volatility'
ORDER BY 
    t2.avg_sales DESC, t1.returned_amount DESC;
