
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN 1 AND 100
), 
SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(rs.ws_sales_price) AS total_revenue,
        MAX(rs.ws_sales_price) AS highest_sale
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    s.s_store_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_revenue, 0) AS total_revenue,
    ss.highest_sale
FROM 
    store s
LEFT JOIN 
    SalesSummary ss ON ss.ws_item_sk IN (
        SELECT DISTINCT cs.cs_item_sk 
        FROM catalog_sales cs 
        WHERE cs.cs_bill_customer_sk IS NOT NULL 
          AND cs.cs_sold_date_sk IN (
              SELECT d.d_date_sk 
              FROM date_dim d 
              WHERE d.d_year = 2001
          ))
ORDER BY 
    s.s_store_name ASC
LIMIT 5 OFFSET 10;
