
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001 
        AND dd.d_moy IN (1, 2, 3)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
), ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    JOIN 
        SalesData sd ON wr.wr_item_sk = sd.ws_item_sk
    GROUP BY 
        wr.wr_item_sk
)

SELECT 
    id.i_item_id,
    id.i_item_desc,
    COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(sd.total_sales, 0) > 0 THEN 
            (COALESCE(rd.total_return_amount, 0) / COALESCE(sd.total_sales, 0)) * 100
        ELSE 0 
    END AS return_percentage,
    CASE 
        WHEN id.i_current_price > 0 THEN 
            ROUND(COALESCE(sd.total_sales, 0) / NULLIF(COUNT(DISTINCT sd.total_orders), 0) / id.i_current_price, 2)
        ELSE 0 
    END AS sales_per_unit_price
FROM 
    item id
LEFT JOIN 
    SalesData sd ON id.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    ReturnData rd ON id.i_item_sk = rd.wr_item_sk
WHERE 
    id.i_rec_start_date <= DATE '2002-10-01'
    AND (id.i_rec_end_date IS NULL OR id.i_rec_end_date > DATE '2002-10-01')
GROUP BY 
    id.i_item_id, id.i_item_desc, sd.total_quantity_sold, rd.total_returns, sd.total_sales, rd.total_return_amount, id.i_current_price
ORDER BY 
    return_percentage DESC, total_sales DESC
LIMIT 50;
