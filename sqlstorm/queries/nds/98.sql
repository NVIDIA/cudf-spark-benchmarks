
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_net_paid_inc_tax) AS average_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451578
    GROUP BY 
        ws_item_sk
),
returns_data AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns 
    WHERE 
        wr_returned_date_sk BETWEEN 2451545 AND 2451578
    GROUP BY 
        wr_item_sk
),
item_data AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit,
        COALESCE(sd.average_net_paid, 0) AS average_net_paid,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount
    FROM 
        item AS i
    LEFT JOIN 
        sales_data AS sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        returns_data AS rd ON i.i_item_sk = rd.wr_item_sk
),
ranked_items AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
        RANK() OVER (ORDER BY total_quantity DESC) AS quantity_rank
    FROM 
        item_data
)
SELECT 
    i.i_item_sk,
    i.i_product_name,
    i.i_current_price,
    r.profit_rank,
    r.quantity_rank,
    CASE 
        WHEN r.profit_rank = 1 THEN 'Top Profitable Item' 
        WHEN r.total_returns > 0 THEN 'Item with Returns' 
        ELSE 'Normal Item' 
    END AS item_status
FROM 
    item_data AS i
JOIN 
    ranked_items AS r ON i.i_item_sk = r.i_item_sk
WHERE 
    i.i_current_price > 10.00
    AND r.total_quantity > 50
ORDER BY 
    r.profit_rank, 
    r.quantity_rank;
