
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer_summary cs
    LEFT JOIN 
        web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.cd_gender, cs.cd_marital_status
    HAVING 
        SUM(ws.ws_ext_sales_price) > (
            SELECT AVG(total_spent) FROM (
                SELECT 
                    SUM(ws_ext_sales_price) AS total_spent
                FROM 
                    web_sales
                GROUP BY 
                    ws_bill_customer_sk
            ) AS avg_spending
        )
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    isum.total_inventory,
    ss.total_sold,
    ss.total_profit
FROM 
    top_customers tc
JOIN 
    inventory_summary isum ON tc.c_customer_sk = (
        SELECT MAX(c.c_customer_sk) 
        FROM customer c 
        WHERE c.c_current_addr_sk IN (
            SELECT ca.ca_address_sk 
            FROM customer_address ca 
            WHERE ca.ca_city IS NOT NULL
        )
    )
LEFT JOIN 
    sales_summary ss ON isum.inv_item_sk = ss.ws_item_sk
ORDER BY 
    tc.cd_gender, ss.total_profit DESC;
