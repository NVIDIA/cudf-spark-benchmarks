
WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_list_price) AS avg_list_price,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
RankedSales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_list_price,
        ss.total_orders,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SalesSummary ss
),
CustomerAnalytics AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    rs.ws_item_sk,
    rs.total_quantity,
    rs.total_sales,
    rs.avg_list_price,
    rs.sales_rank,
    ca.orders_count,
    ca.total_spent,
    COALESCE(ca.total_spent / NULLIF(ca.orders_count, 0), 0) AS average_spent_per_order
FROM 
    RankedSales rs
LEFT JOIN 
    CustomerAnalytics ca ON rs.ws_item_sk = ca.c_customer_sk
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.sales_rank;
