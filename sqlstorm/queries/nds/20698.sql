
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price BETWEEN 10.00 AND 100.00
        AND ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_dow IN (1, 2, 3)
        )
    GROUP BY 
        ws.ws_item_sk
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_profit,
        COALESCE(NULLIF(rs.total_net_profit, 0) / NULLIF(rs.total_quantity, 0), -1) AS profit_per_unit,
        CASE 
            WHEN rs.total_net_profit > 0 THEN 'Profitable'
            WHEN rs.total_net_profit < 0 THEN 'Loss'
            ELSE 'Break-even'
        END AS profit_status
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_profit = 1 
        OR rs.total_net_profit < 0
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        fs.total_quantity,
        fs.total_net_profit,
        fs.profit_per_unit,
        fs.profit_status
    FROM 
        FilteredSales fs
    JOIN 
        item i ON fs.ws_item_sk = i.i_item_sk
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.total_quantity,
    id.total_net_profit,
    id.profit_per_unit,
    id.profit_status,
    CASE 
        WHEN id.profit_status = 'Profitable' THEN 'Great job!'
        WHEN id.profit_status = 'Loss' THEN 'Consider reviewing this item.'
        ELSE 'Stable performance.'
    END AS advisory,
    (SELECT COUNT(DISTINCT c.c_customer_sk)
     FROM customer c 
     WHERE c.c_current_cdemo_sk IN (
         SELECT cd.cd_demo_sk 
         FROM customer_demographics cd 
         WHERE cd.cd_gender = 'F' AND cd.cd_credit_rating NOT IN ('Poor', 'Fair')
     )
    ) AS total_premium_customers
FROM 
    ItemDetails id
WHERE 
    id.profit_per_unit > 5 
ORDER BY 
    id.total_net_profit DESC
LIMIT 10;
