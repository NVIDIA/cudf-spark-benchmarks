WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_list_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rankSales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk 
                            FROM date_dim 
                            WHERE d_year = 2001 AND d_month_seq BETWEEN 1 AND 6)
),
AggregateSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        AVG(rs.ws_list_price) AS avg_list_price
    FROM 
        RankedSales rs
    WHERE 
        rs.rankSales = 1
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns 
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk 
                                 FROM date_dim 
                                 WHERE d_year = 2001 AND d_dow IN (6, 0)) 
    GROUP BY 
        sr_item_sk
)
SELECT 
    a.ws_item_sk,
    a.total_quantity,
    a.avg_list_price,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_returned, 0) AS total_returned,
    CASE 
        WHEN a.total_quantity > COALESCE(cr.total_returned, 0) THEN 'More Sales'
        WHEN a.total_quantity < COALESCE(cr.total_returned, 0) THEN 'More Returns'
        ELSE 'Equal Sales and Returns'
    END AS sales_vs_returns
FROM 
    AggregateSales a
LEFT JOIN 
    CustomerReturns cr ON a.ws_item_sk = cr.sr_item_sk
WHERE 
    a.total_quantity > (SELECT AVG(total_quantity) 
                        FROM AggregateSales 
                        WHERE total_quantity IS NOT NULL) * 1.5
ORDER BY 
    a.total_quantity DESC;