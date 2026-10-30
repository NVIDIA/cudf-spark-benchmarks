
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        COUNT(DISTINCT wr_order_number) AS distinct_orders
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
InventoryCheck AS (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_stock
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
SalesWithReturns AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        COALESCE(cr.total_returns, 0) AS total_returns,
        ic.total_stock,
        CASE 
            WHEN ic.total_stock < (rs.total_quantity - COALESCE(cr.total_returns, 0)) 
            THEN 'Out of Stock' 
            ELSE 'In Stock' 
        END AS stock_status
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.ws_item_sk = cr.wr_item_sk
    JOIN 
        InventoryCheck ic ON rs.ws_item_sk = ic.inv_item_sk
)
SELECT 
    s.ws_item_sk, 
    s.total_quantity, 
    s.total_returns, 
    s.total_stock, 
    s.stock_status
FROM 
    SalesWithReturns s
WHERE 
    s.total_quantity > (s.total_returns + 5) 
    AND s.stock_status = 'In Stock'
    AND s.ws_item_sk IN (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_sold_date_sk BETWEEN 
            (SELECT MAX(d_date_sk) FROM date_dim WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = 2023)) 
            AND 
            (SELECT MAX(d_date_sk) FROM date_dim WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = 2023) - 2)
    )
ORDER BY 
    s.total_quantity DESC;
