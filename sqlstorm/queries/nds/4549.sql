
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss.ss_store_sk ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        c.c_customer_id, ss.ss_store_sk
),
PopularItems AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(*) AS sales_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
CustomersWithReturns AS (
    SELECT 
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(ri.total_returns, 0) AS total_returns,
    pi.sales_count AS popular_item_sales_count,
    CASE 
        WHEN COALESCE(rs.total_sales, 0) > 5000 THEN 'High Value Customer'
        WHEN COALESCE(rs.total_sales, 0) BETWEEN 1000 AND 5000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM 
    customer c
LEFT JOIN 
    RankedSales rs ON c.c_customer_id = rs.c_customer_id
LEFT JOIN 
    CustomersWithReturns ri ON ri.customer_sk = c.c_customer_sk
LEFT JOIN 
    PopularItems pi ON pi.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'Brand A')
WHERE 
    (rs.sales_rank IS NULL OR rs.sales_rank <= 10) 
    AND (ri.total_returns IS NULL OR ri.total_returns < 1000)
ORDER BY 
    total_sales DESC;
