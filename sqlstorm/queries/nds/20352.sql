
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales AS ws
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6
        )
    GROUP BY 
        ws_item_sk
),
FilterSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_profit,
        COALESCE(pm.p_promo_name, 'No Promo') AS promo_name
    FROM 
        RankedSales AS rs
    LEFT JOIN 
        promotion AS pm ON pm.p_item_sk = rs.ws_item_sk
    WHERE 
        rs.rank = 1
        AND rs.total_quantity > (
            SELECT AVG(total_quantity) 
            FROM RankedSales
        )
),
SalesInequality AS (
    SELECT 
        item.i_item_id,
        fs.total_quantity,
        fs.total_net_profit,
        CASE 
            WHEN fs.total_net_profit IS NULL THEN 'Profit Data Missing'
            WHEN fs.total_net_profit > 1000 THEN 'High Profit'
            ELSE 'Low Profit'
        END AS profit_category,
        fs.ws_item_sk
    FROM 
        FilterSales AS fs
    JOIN 
        item AS item ON fs.ws_item_sk = item.i_item_sk
)
SELECT 
    sa.i_item_id AS item,
    sa.total_quantity,
    sa.total_net_profit,
    sa.profit_category,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    MAX(ws.ws_ship_date_sk) AS last_ship_date
FROM 
    SalesInequality AS sa
LEFT JOIN 
    web_sales AS ws ON sa.ws_item_sk = ws.ws_item_sk
GROUP BY 
    sa.i_item_id, sa.total_quantity, sa.total_net_profit, sa.profit_category
HAVING 
    COUNT(ws.ws_order_number) >= COALESCE(
        (SELECT AVG(order_count) 
         FROM (SELECT COUNT(*) AS order_count 
               FROM web_sales 
               GROUP BY ws_item_sk) AS subquery), 5
    )
ORDER BY 
    sa.total_net_profit DESC NULLS LAST;
