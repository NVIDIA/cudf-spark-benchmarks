
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
high_profit_items AS (
    SELECT 
        item.i_item_sk,
        item.i_product_name,
        item.i_current_price,
        ranked_sales.total_net_profit
    FROM 
        item
    JOIN 
        ranked_sales ON item.i_item_sk = ranked_sales.ws_item_sk
    WHERE 
        ranked_sales.rank_profit = 1
),
customer_return_data AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_quantity) AS total_return_quantity
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
final_selection AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        hpi.i_product_name,
        hpi.total_net_profit,
        crd.total_returns,
        crd.total_return_amt,
        crd.total_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        high_profit_items hpi ON hpi.total_net_profit > 0
    LEFT JOIN 
        customer_return_data crd ON c.c_customer_sk = crd.wr_returning_customer_sk
    WHERE 
        ca.ca_city IS NOT NULL
        AND hpi.total_net_profit > 1000
)
SELECT 
    *
FROM 
    final_selection
WHERE 
    (total_returns IS NULL OR total_return_quantity < 10)
ORDER BY 
    total_net_profit DESC
LIMIT 20;
