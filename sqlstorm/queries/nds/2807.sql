
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
returns_summary AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_net_loss) AS total_return_loss
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
combined_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_net_profit,
        COALESCE(rs.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(rs.total_return_loss, 0) AS total_return_loss,
        (ss.total_net_profit - COALESCE(rs.total_return_loss, 0)) AS net_profit_after_returns
    FROM 
        sales_summary ss
    LEFT JOIN 
        returns_summary rs ON ss.ws_item_sk = rs.wr_item_sk
)
SELECT 
    ci.i_item_id,
    ci.i_item_desc,
    cs.total_quantity,
    cs.total_net_profit,
    cs.total_return_quantity,
    cs.net_profit_after_returns,
    RANK() OVER (ORDER BY cs.net_profit_after_returns DESC) AS profit_rank
FROM 
    combined_sales cs
JOIN 
    item ci ON cs.ws_item_sk = ci.i_item_sk
WHERE 
    cs.net_profit_after_returns > 0
ORDER BY 
    cs.net_profit_after_returns DESC
LIMIT 10;
