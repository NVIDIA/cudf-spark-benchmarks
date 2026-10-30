WITH RankedSales AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk = (SELECT d.d_date_sk 
                               FROM date_dim d 
                               WHERE d.d_date = cast('2002-10-01' as date))
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
CustomerReturns AS (
    SELECT 
        sr.sr_store_sk,
        COUNT(*) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr 
    JOIN 
        customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        sr.sr_store_sk
),
StorePerformance AS (
    SELECT 
        rs.s_store_sk,
        rs.s_store_name,
        rs.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        (rs.total_sales - COALESCE(cr.total_return_amt, 0)) AS net_sales
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.s_store_sk = cr.sr_store_sk
)
SELECT 
    sp.s_store_name,
    sp.total_sales,
    sp.total_returns,
    sp.total_return_amt,
    sp.net_sales,
    CASE 
        WHEN sp.net_sales < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS performance
FROM 
    StorePerformance sp
WHERE 
    sp.net_sales > 1000
ORDER BY 
    sp.net_sales DESC;