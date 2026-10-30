
WITH RankedSales AS (
    SELECT 
        s.ss_store_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_paid) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY s.ss_store_sk ORDER BY SUM(s.ss_net_paid) DESC) AS revenue_rank
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        s.ss_store_sk, s.ss_item_sk
),
TopStores AS (
    SELECT 
        rs.ss_store_sk,
        s.s_store_name,
        rs.total_quantity,
        rs.total_revenue
    FROM 
        RankedSales rs
    JOIN 
        store s ON rs.ss_store_sk = s.s_store_sk
    WHERE 
        rs.revenue_rank <= 5
),
CustomerReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        COUNT(wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
FinalOutput AS (
    SELECT 
        ts.s_store_name,
        ts.total_quantity,
        ts.total_revenue,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN cr.return_count > 0 THEN 
                ROUND((cr.total_return_amt / ts.total_revenue) * 100, 2)
            ELSE 
                0 
        END AS return_percentage
    FROM 
        TopStores ts
    LEFT JOIN 
        CustomerReturns cr ON ts.ss_store_sk = cr.wr_returning_customer_sk
)
SELECT 
    f.s_store_name,
    f.total_quantity,
    f.total_revenue,
    f.return_count,
    f.total_return_amt,
    f.return_percentage,
    CASE 
        WHEN f.return_percentage > 10 THEN 'High Return Rate'
        WHEN f.return_percentage BETWEEN 5 AND 10 THEN 'Moderate Return Rate'
        ELSE 'Low Return Rate'
    END AS return_rate_category
FROM 
    FinalOutput f
ORDER BY 
    f.total_revenue DESC;
