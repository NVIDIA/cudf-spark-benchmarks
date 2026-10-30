
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
StoreReturnsSummary AS (
    SELECT 
        d.d_year,
        SUM(sr.sr_return_amt) AS total_store_returns
    FROM 
        store_returns sr
    JOIN 
        date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ss.d_year,
    ss.total_web_sales,
    ss.total_orders,
    ss.unique_customers,
    COALESCE(srs.total_store_returns, 0) AS total_store_returns,
    CASE 
        WHEN ss.total_orders > 0 THEN 
            ROUND(CAST(ss.total_web_sales AS DECIMAL) / ss.total_orders, 2)
        ELSE 
            0
    END AS avg_order_value,
    RANK() OVER (ORDER BY ss.total_web_sales DESC) AS sales_rank
FROM 
    SalesSummary ss
LEFT JOIN 
    StoreReturnsSummary srs ON ss.d_year = srs.d_year
ORDER BY 
    ss.d_year ASC;
