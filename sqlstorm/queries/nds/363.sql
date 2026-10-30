
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        COALESCE(SUM(cr.cr_return_quantity) OVER (PARTITION BY ws.ws_item_sk), 0) AS total_returns,
        (ws.ws_sales_price * ws.ws_quantity) AS total_sales_value
    FROM 
        web_sales ws
    LEFT JOIN 
        web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
    LEFT JOIN 
        catalog_returns cr ON ws.ws_item_sk = cr.cr_item_sk AND ws.ws_order_number = cr.cr_order_number
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
        AND ws.ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(rs.ws_order_number) AS order_count,
        SUM(rs.total_sales_value) AS total_sales,
        AVG(rs.ws_sales_price) AS avg_sales_price,
        SUM(rs.total_returns) AS total_returns,
        SUM(CASE WHEN rs.sales_rank = 1 THEN rs.total_sales_value ELSE 0 END) AS top_sales_value
    FROM 
        RankedSales rs
    GROUP BY 
        rs.ws_item_sk
)

SELECT 
    ca.ca_country,
    SUM(ss.total_sales) AS country_total_sales,
    COUNT(DISTINCT ss.ws_item_sk) AS unique_items_sold,
    AVG(ss.avg_sales_price) AS average_item_price,
    (SUM(ss.total_sales) - SUM(ss.total_returns * 0.5)) AS net_sales_value
FROM 
    SalesSummary ss
INNER JOIN 
    customer_address ca ON (ss.ws_item_sk = ca.ca_address_sk) 
GROUP BY 
    ca.ca_country
HAVING 
    COUNT(DISTINCT ss.ws_item_sk) > 10
ORDER BY 
    country_total_sales DESC
LIMIT 5;
