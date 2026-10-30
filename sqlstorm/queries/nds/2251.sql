
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
HighProfitItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
    FROM 
        RankedSales rs
    JOIN 
        item ON rs.ws_item_sk = item.i_item_sk
    LEFT JOIN 
        web_sales ws ON rs.ws_order_number = ws.ws_order_number AND rs.ws_item_sk = ws.ws_item_sk
    WHERE 
        rs.profit_rank = 1
    GROUP BY 
        item.i_item_id, item.i_item_desc
),
CustomerStats AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    hs.i_item_id,
    hs.i_item_desc,
    hs.total_net_profit,
    cs.ca_state,
    cs.customer_count,
    cs.male_count,
    cs.female_count
FROM 
    HighProfitItems hs
JOIN 
    CustomerStats cs ON hs.total_net_profit > 1000
ORDER BY 
    hs.total_net_profit DESC, cs.customer_count DESC
LIMIT 10;
