
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND i.i_category = 'Electronics'
    GROUP BY 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_profit,
        i.i_product_name,
        ROW_NUMBER() OVER (ORDER BY rs.total_net_profit DESC) AS top_rank
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank = 1
)
SELECT 
    ts.top_rank,
    ts.i_product_name,
    ts.total_quantity,
    ts.total_net_profit
FROM 
    TopSales ts
WHERE 
    ts.top_rank <= 10
ORDER BY 
    ts.total_net_profit DESC;
