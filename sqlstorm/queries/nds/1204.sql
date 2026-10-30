
WITH RankedSales AS (
    SELECT
        ss_store_sk,
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_sales,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM
        store_sales
    WHERE
        ss_sold_date_sk BETWEEN 2451545 AND 2451919 
    GROUP BY
        ss_store_sk, ss_item_sk, ss_sold_date_sk
),
TopStores AS (
    SELECT 
        ss_store_sk,
        AVG(total_net_sales) AS avg_sales
    FROM
        RankedSales
    WHERE
        sales_rank <= 5  
    GROUP BY
        ss_store_sk
),
CustomerReturns AS (
    SELECT
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        COALESCE(SUM(sr_return_quantity), 0) AS total_return_quantity 
    FROM
        store_returns
    GROUP BY
        sr_store_sk
)
SELECT 
    s.s_store_name,
    COALESCE(ts.avg_sales, 0) AS average_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amt, 0) AS total_return_amount,
    COALESCE(cr.total_return_quantity, 0) AS total_return_quantity
FROM 
    store s
LEFT JOIN 
    TopStores ts ON s.s_store_sk = ts.ss_store_sk
LEFT JOIN 
    CustomerReturns cr ON s.s_store_sk = cr.sr_store_sk
WHERE 
    s.s_number_employees > 50 
ORDER BY 
    average_sales DESC, 
    total_returns DESC;
