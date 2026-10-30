
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
        AND cd.cd_gender = 'F'
),
TopSales AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_net_profit) AS total_net_profit,
        COUNT(rs.ws_item_sk) AS item_count,
        COUNT(DISTINCT rs.ca_city) AS unique_cities
    FROM 
        RankedSales rs
    WHERE 
        rs.rn = 1
    GROUP BY 
        rs.ws_order_number
)
SELECT 
    ts.ws_order_number,
    ts.total_net_profit,
    ts.item_count,
    ts.unique_cities,
    DENSE_RANK() OVER (ORDER BY ts.total_net_profit DESC) AS rank_profit
FROM 
    TopSales ts
ORDER BY 
    rank_profit
LIMIT 10;
