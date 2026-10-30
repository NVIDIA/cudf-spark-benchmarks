
WITH  CTE_Sales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year >= 2020
    GROUP BY 
        ws.ws_item_sk
),
Top_Sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_sales
    FROM 
        CTE_Sales sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.rank <= 10
),
Customer_Summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
High_Value_Customers AS (
    SELECT 
        cu.c_customer_id,
        cu.total_purchases,
        cu.total_net_profit,
        cu.avg_sales_price,
        CASE 
            WHEN cu.total_net_profit > 1000 THEN 'Gold'
            WHEN cu.total_net_profit BETWEEN 500 AND 1000 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier
    FROM 
        Customer_Summary cu
    WHERE 
        cu.total_purchases > 5
)
SELECT 
    t.i_item_id AS item_id,
    t.i_item_desc AS item_desc,
    t.total_quantity,
    t.total_sales,
    h.c_customer_id,
    h.customer_tier,
    h.total_purchases,
    h.total_net_profit
FROM 
    Top_Sales t
LEFT JOIN 
    High_Value_Customers h ON h.total_purchases > 5
ORDER BY 
    t.total_sales DESC, h.total_net_profit DESC;
