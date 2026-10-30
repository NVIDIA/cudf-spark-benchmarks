
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COALESCE(wp.wp_url, 'No URL') AS web_page_url,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE 
        ws.ws_ship_date_sk > 0
        AND ws.ws_sales_price IS NOT NULL
),
AggregatedSales AS (
    SELECT 
        c_customer_id,
        COUNT(*) AS total_sales,
        SUM(ws_sales_price) AS total_revenue,
        AVG(ws_sales_price) AS avg_sales_price,
        MAX(ws_sales_price) AS max_sales_price,
        MIN(ws_sales_price) AS min_sales_price
    FROM 
        RankedSales
    GROUP BY 
        c_customer_id
)
SELECT 
    a.c_customer_id,
    a.total_sales,
    a.total_revenue,
    a.avg_sales_price,
    COALESCE(b.web_page_url, 'No Page') AS web_page_url,
    CASE 
        WHEN a.total_sales >= 10 THEN 'High Roller'
        WHEN a.total_sales BETWEEN 5 AND 9 THEN 'Regular'
        ELSE 'Casual'
    END AS customer_type
FROM 
    AggregatedSales a
    LEFT JOIN (SELECT c_customer_id, MAX(web_page_url) AS web_page_url FROM RankedSales GROUP BY c_customer_id) b 
    ON a.c_customer_id = b.c_customer_id
WHERE 
    a.total_revenue > 1000
    OR (a.total_sales > 5 AND EXISTS (SELECT 1 FROM RankedSales r WHERE r.c_customer_id = a.c_customer_id AND r.profit_rank = 1))
ORDER BY 
    a.total_revenue DESC, 
    a.total_sales DESC;
