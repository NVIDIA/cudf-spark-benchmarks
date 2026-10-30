
WITH  sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        (CASE 
            WHEN ws.ws_sales_price IS NULL THEN 'No Price'
            WHEN ws.ws_net_paid < 0 THEN 'Loss'
            ELSE 'Profit'
        END) AS profitability_status
    FROM 
        web_sales ws 
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        i.i_current_price IS NOT NULL
        AND ws.ws_quantity > 0
),
return_summary AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
final_summary AS (
    SELECT 
        sd.ws_item_sk,
        COALESCE(sd.ws_sales_price, 0) AS final_sales_price,
        sd.ws_quantity,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        sd.profitability_status,
        CASE 
            WHEN sd.profitability_status = 'Loss' THEN 
                SUM(sd.ws_sales_price) OVER (PARTITION BY sd.profitability_status ORDER BY sd.ws_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            ELSE 
                0
        END AS accumulated_loss
    FROM 
        sales_data sd
    LEFT JOIN 
        return_summary rs ON sd.ws_item_sk = rs.cr_item_sk
    WHERE 
        sd.profit_rank <= 10
)
SELECT 
    fs.ws_item_sk,
    fs.final_sales_price,
    fs.ws_quantity,
    fs.total_returns,
    fs.total_return_amount,
    fs.profitability_status,
    fs.accumulated_loss
FROM 
    final_summary fs
WHERE 
    (fs.final_sales_price > 0 OR fs.total_returns > 5)
    AND (fs.profitability_status = 'Profit' OR fs.profitability_status = 'Loss')
ORDER BY 
    fs.final_sales_price DESC
LIMIT 20;
