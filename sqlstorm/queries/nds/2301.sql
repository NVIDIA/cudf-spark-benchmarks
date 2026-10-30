
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        coalesce(hd.hd_buy_potential, 'Standard') AS buy_potential
    FROM 
        item i
    LEFT JOIN customer c ON i.i_item_sk = c.c_current_addr_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        id.i_item_sk,
        id.i_item_desc,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM 
        ItemDetails id
    JOIN RankedSales rs ON id.i_item_sk = rs.ws_item_sk
    WHERE 
        rs.rnk <= 5 
    GROUP BY 
        id.i_item_sk, id.i_item_desc
)
SELECT 
    ss.i_item_sk,
    ss.i_item_desc,
    ss.total_quantity,
    ss.total_net_profit,
    id.gender,
    id.buy_potential,
    CASE 
        WHEN ss.total_net_profit > 1000 THEN 'High Profit'
        WHEN ss.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    SalesSummary ss
JOIN ItemDetails id ON ss.i_item_sk = id.i_item_sk
ORDER BY 
    ss.total_net_profit DESC
LIMIT 10;
