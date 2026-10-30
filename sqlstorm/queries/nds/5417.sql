
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopProfitableItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        rs.total_quantity,
        rs.total_profit,
        rs.ws_item_sk
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.profit_rank <= 10
)
SELECT 
    tpi.i_item_id,
    tpi.i_product_name,
    tpi.total_quantity,
    tpi.total_profit,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders
FROM 
    TopProfitableItems tpi
JOIN 
    catalog_sales cs ON cs.cs_item_sk = tpi.ws_item_sk
JOIN 
    customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY 
    tpi.i_item_id, 
    tpi.i_product_name, 
    tpi.total_quantity, 
    tpi.total_profit,
    ca.ca_city,
    ca.ca_state
ORDER BY 
    tpi.total_profit DESC;
