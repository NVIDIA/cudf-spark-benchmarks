
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
TopProducts AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_profit
    FROM 
        SalesData sales
    JOIN 
        item ON item.i_item_sk = sales.ws_item_sk
    WHERE 
        sales.rank <= 5
),
CustomerStats AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(CASE WHEN c.c_current_addr_sk IS NOT NULL THEN 1 ELSE 0 END) AS active_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_credit_rating) AS highest_credit_rating
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    tp.i_item_id, 
    tp.i_item_desc, 
    tp.total_quantity, 
    tp.total_profit, 
    cs.active_customers, 
    cs.avg_purchase_estimate, 
    cs.highest_credit_rating
FROM 
    TopProducts tp
LEFT JOIN 
    CustomerStats cs ON cs.cd_demo_sk = (SELECT MAX(cd_demo_sk) FROM CustomerStats)
ORDER BY 
    tp.total_profit DESC
LIMIT 10;
