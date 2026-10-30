
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 10000 AND 10005
    GROUP BY 
        ws_item_sk
),
BestSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        rs.total_quantity,
        rs.total_net_profit
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 10
),
CustomerTotals AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    bsi.i_item_id,
    bsi.i_product_name,
    bsi.total_quantity,
    bsi.total_net_profit,
    ct.order_count,
    ct.total_spent
FROM 
    BestSellingItems bsi
JOIN 
    CustomerTotals ct ON ct.total_spent > 1000
ORDER BY 
    bsi.total_net_profit DESC, ct.total_spent DESC;
