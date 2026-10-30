WITH SalesData AS (
    SELECT 
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2000
        AND dd.d_moy IN (3, 4, 5)  
    GROUP BY 
        ws.ws_item_sk
),
InventoryData AS (
    SELECT 
        inv.inv_item_sk AS item_sk,
        SUM(inv.inv_quantity_on_hand) AS quantity_on_hand
    FROM 
        inventory AS inv
    INNER JOIN 
        warehouse AS w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        inv.inv_item_sk
),
ReturnsData AS (
    SELECT 
        wr.wr_item_sk AS item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns AS wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    id.item_sk,
    sd.total_quantity,
    sd.total_sales,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    id.quantity_on_hand,
    sd.order_count,
    CASE 
        WHEN sd.total_sales > 0 THEN (sd.total_sales - sd.total_discount) / sd.total_sales
        ELSE NULL 
    END AS sales_margin
FROM 
    SalesData AS sd
LEFT JOIN 
    InventoryData AS id ON sd.item_sk = id.item_sk
LEFT JOIN 
    ReturnsData AS rd ON sd.item_sk = rd.item_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 10;