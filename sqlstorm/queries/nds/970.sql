
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (
            SELECT MIN(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023
        )
    GROUP BY 
        c.c_customer_id
    HAVING 
        COUNT(ws.ws_order_number) > 5
), 
ReturnsSummary AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
), 
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        r.total_returns,
        rs.total_orders,
        rs.total_sales,
        (CASE 
            WHEN rs.total_sales IS NULL OR rs.total_sales = 0 THEN NULL 
            ELSE (r.total_returns / NULLIF(rs.total_sales, 0)) 
        END) AS return_to_sales_ratio
    FROM 
        customer c
    LEFT JOIN 
        ReturnsSummary r ON c.c_customer_sk = r.sr_customer_sk
    LEFT JOIN 
        RankedSales rs ON c.c_customer_id = rs.c_customer_id
)
SELECT 
    cs.c_customer_id,
    COALESCE(cs.total_orders, 0) AS orders_made,
    COALESCE(cs.total_sales, 0) AS sales_made,
    COALESCE(cs.total_returns, 0) AS returns_made,
    COALESCE(cs.return_to_sales_ratio, 0) AS return_to_sales_ratio
FROM 
    CustomerStats cs
WHERE 
    cs.return_to_sales_ratio < 0.5
ORDER BY 
    cs.return_to_sales_ratio DESC;
