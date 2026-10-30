WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    GROUP BY 
        c.c_customer_id
),
StoreSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    GROUP BY 
        c.c_customer_id
),
CombinedSales AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS grand_total_sales,
        (cs.total_orders + ss.total_store_orders) AS total_orders
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_id = ss.c_customer_id
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY grand_total_sales DESC) AS sales_rank
    FROM 
        CombinedSales
)
SELECT 
    c.c_customer_id,
    COALESCE(total_web_sales, 0) AS total_web_sales,
    COALESCE(total_store_sales, 0) AS total_store_sales,
    grand_total_sales,
    total_orders,
    sales_rank
FROM 
    RankedSales rs
JOIN 
    customer c ON rs.c_customer_id = c.c_customer_id
WHERE 
    c.c_birth_year < 1980 
    AND (grand_total_sales > 1000 OR sales_rank <= 10) 
ORDER BY 
    sales_rank;