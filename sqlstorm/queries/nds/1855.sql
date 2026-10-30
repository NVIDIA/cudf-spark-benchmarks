
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COALESCE(sd.cd_gender, 'Unknown') AS customer_gender,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS total_profit
    FROM 
        web_sales AS ws
    LEFT JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics AS sd ON c.c_current_cdemo_sk = sd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim AS d WHERE d.d_year = 2023)
),
FilteredReturns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        AVG(wr.wr_return_amt) AS avg_return_amount
    FROM 
        web_returns AS wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    rs.total_quantity_sold,
    rs.total_profit,
    fr.total_return_quantity,
    fr.avg_return_amount,
    rs.customer_gender
FROM 
    item AS i
JOIN 
    RankedSales AS rs ON i.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    FilteredReturns AS fr ON i.i_item_sk = fr.wr_item_sk
WHERE 
    (rs.price_rank = 1 OR rs.customer_gender = 'F')
    AND rs.total_profit > (SELECT AVG(total_profit) FROM RankedSales)
GROUP BY 
    i.i_item_id,
    i.i_item_desc,
    rs.total_quantity_sold,
    rs.total_profit,
    fr.total_return_quantity,
    fr.avg_return_amount,
    rs.customer_gender
ORDER BY 
    total_profit DESC, total_quantity_sold DESC
LIMIT 100;
