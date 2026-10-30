
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as Rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
),
TopItems AS (
    SELECT 
        r.ws_item_sk, 
        SUM(r.ws_quantity) AS total_quantity, 
        AVG(r.ws_net_profit) AS avg_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.Rank <= 5
    GROUP BY 
        r.ws_item_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('NY', 'CA')
),
SalesSummary AS (
    SELECT 
        ti.ws_item_sk,
        ad.ca_city,
        ad.ca_state,
        ti.total_quantity,
        ti.avg_net_profit,
        CASE 
            WHEN ti.avg_net_profit IS NULL THEN 'No Profit Data' 
            ELSE 'Profit Available' 
        END AS profit_status
    FROM 
        TopItems ti
    LEFT JOIN 
        AddressDetails ad ON ti.ws_item_sk = ad.ca_address_sk
)
SELECT 
    ss.ws_item_sk,
    COALESCE(ss.ca_city, 'Unknown') AS city,
    COALESCE(ss.ca_state, 'Unknown') AS state,
    ss.total_quantity,
    ss.avg_net_profit,
    ss.profit_status
FROM 
    SalesSummary ss
ORDER BY 
    ss.total_quantity DESC
LIMIT 
    10;
