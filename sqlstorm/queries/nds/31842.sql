
WITH  Sales_CTE AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= 2459938 
    GROUP BY 
        ws.ws_order_number, 
        ws.ws_item_sk
), 
Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS tickets_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
), 
Item_Review AS (
    SELECT 
        item.i_item_sk,
        item.i_item_desc,
        AVG(ss.ss_net_profit) AS avg_profit,
        COUNT(ss.ss_ticket_number) AS sales_count
    FROM 
        item 
    JOIN 
        store_sales ss ON item.i_item_sk = ss.ss_item_sk
    GROUP BY 
        item.i_item_sk, 
        item.i_item_desc
), 
Top_Items AS (
    SELECT 
        ir.i_item_sk,
        ir.i_item_desc,
        ir.avg_profit,
        ir.sales_count,
        ROW_NUMBER() OVER (ORDER BY ir.avg_profit DESC) AS rank
    FROM 
        Item_Review ir
    WHERE 
        ir.sales_count > 10
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    ti.i_item_desc,
    ti.avg_profit,
    COALESCE(sc.total_net_profit, 0) AS web_net_profit,
    COALESCE(SUM(sc.total_quantity), 0) AS total_web_quantity
FROM 
    Customer_Sales cs
LEFT JOIN 
    Top_Items ti ON cs.c_customer_sk = ti.i_item_sk
LEFT JOIN 
    Sales_CTE sc ON ti.i_item_sk = sc.ws_item_sk
WHERE 
    cs.total_store_profit > (SELECT AVG(total_store_profit) FROM Customer_Sales)
    AND ti.rank <= 5
GROUP BY 
    cs.c_first_name, 
    cs.c_last_name, 
    ti.i_item_desc, 
    ti.avg_profit, 
    sc.total_net_profit
ORDER BY 
    cs.c_last_name, 
    cs.c_first_name;
