
WITH RankedSales AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 2452000 AND ws_sold_date_sk <= 2452642
),
InventoryStatus AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity,
        MAX(inv_date_sk) AS last_update
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
TopItems AS (
    SELECT 
        r.ws_item_sk,
        r.ws_sales_price,
        r.ws_quantity,
        i.total_quantity
    FROM 
        RankedSales r
    INNER JOIN 
        InventoryStatus i ON r.ws_item_sk = i.inv_item_sk
    WHERE 
        r.price_rank <= 10
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    t.ws_item_sk,
    t.ws_sales_price,
    t.ws_quantity,
    t.total_quantity,
    COALESCE(c.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(c.total_return_amt, 0.00) AS total_return_amt,
    CASE 
        WHEN t.total_quantity IS NULL THEN 'Out of Stock'
        WHEN COALESCE(c.total_return_quantity, 0) > t.ws_quantity THEN 'High Return Rate'
        ELSE 'Normal'
    END AS inventory_status
FROM 
    TopItems t
LEFT JOIN 
    CustomerReturns c ON t.ws_item_sk = c.wr_item_sk
ORDER BY 
    t.ws_sales_price DESC, 
    t.total_quantity ASC;
