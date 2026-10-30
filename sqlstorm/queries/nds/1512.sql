
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        ca.ca_city,
        ca.ca_state
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        i.i_current_price > 10.00 
        AND c.c_birth_year BETWEEN 1980 AND 1990
),
TopSales AS (
    SELECT 
        rs.ca_city,
        rs.ca_state,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_profit) AS total_profit
    FROM 
        RankedSales AS rs
    WHERE 
        rs.profit_rank <= 5
    GROUP BY 
        rs.ca_city, rs.ca_state
)
SELECT 
    ts.ca_city,
    ts.ca_state,
    ts.total_quantity,
    ts.total_profit,
    COALESCE(ts.total_profit / NULLIF(ts.total_quantity, 0), 0) AS avg_profit_per_unit
FROM 
    TopSales AS ts
ORDER BY 
    ts.total_profit DESC
LIMIT 10;
