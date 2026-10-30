
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS rank_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk = (SELECT MAX(ws2.ws_ship_date_sk) FROM web_sales ws2)
),
TopSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_profit <= 3 OR rs.rank_quantity <= 3
),
SalesSummary AS (
    SELECT 
        i.i_item_id,
        SUM(ts.ws_quantity) AS total_quantity,
        SUM(ts.ws_net_profit) AS total_net_profit
    FROM 
        TopSales ts
    JOIN 
        item i ON ts.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
    HAVING 
        SUM(ts.ws_quantity) > 10
)
SELECT 
    ss.i_item_id,
    ss.total_quantity,
    ss.total_net_profit,
    ca.ca_country,
    cd.cd_gender,
    COALESCE(NULLIF(ss.total_net_profit / NULLIF(ss.total_quantity, 0), 0), 0) AS average_profit_per_item
FROM 
    SalesSummary ss
LEFT JOIN 
    customer c ON ss.total_quantity > c.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_country IS NOT NULL
ORDER BY 
    ss.total_net_profit DESC
LIMIT 100;
