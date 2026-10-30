
WITH  MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
    
    UNION ALL
    
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
RankedSales AS (
    SELECT 
        m.d_year,
        m.d_month_seq,
        m.total_sales,
        RANK() OVER (PARTITION BY m.d_year ORDER BY m.total_sales DESC) AS sales_rank
    FROM 
        MonthlySales m
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    r.d_year,
    r.d_month_seq,
    r.total_sales,
    r.sales_rank,
    COALESCE(cp.total_orders, 0) AS total_orders,
    COALESCE(cp.total_spent, 0) AS total_spent
FROM 
    RankedSales r
LEFT JOIN 
    CustomerPurchases cp ON r.sales_rank = cp.total_orders
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.d_year, r.d_month_seq;
