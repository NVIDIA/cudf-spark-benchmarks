
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopProducts AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_orders,
        rs.total_net_profit
    FROM 
        item i
    JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE 
        rs.rank <= 10
),
CustomerOverview AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_spent,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    co.c_customer_id,
    co.order_count,
    co.total_spent,
    co.last_purchase_date,
    tp.i_item_id,
    tp.i_item_desc,
    tp.total_orders,
    tp.total_net_profit
FROM 
    CustomerOverview co
JOIN 
    TopProducts tp ON co.total_spent > 1000 AND co.order_count > 5
ORDER BY 
    co.total_spent DESC, tp.total_net_profit DESC
LIMIT 50;
