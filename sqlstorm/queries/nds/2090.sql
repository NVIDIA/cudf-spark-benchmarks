
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
), 
TotalSales AS (
    SELECT 
        item.i_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_revenue
    FROM 
        item
    JOIN 
        RankedSales rs ON item.i_item_sk = rs.ws_item_sk
    WHERE 
        rs.rank_sales = 1
    GROUP BY 
        item.i_item_sk
), 
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
)

SELECT 
    i.i_item_id,
    COALESCE(ts.total_revenue, 0) AS total_sales_revenue,
    COALESCE(cr.return_count, 0) AS total_return_count,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(cr.total_return_amount, 0) > 0 THEN 
            (COALESCE(ts.total_revenue, 0) - COALESCE(cr.total_return_amount, 0)) / NULLIF(COALESCE(ts.total_revenue, 0), 0)
        ELSE 
            1.0 
    END AS revenue_return_ratio
FROM 
    item i
LEFT JOIN 
    TotalSales ts ON i.i_item_sk = ts.i_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
WHERE 
    (COALESCE(ts.total_revenue, 0) > 1000 OR COALESCE(cr.return_count, 0) > 0)
ORDER BY 
    total_sales_revenue DESC
LIMIT 100;
