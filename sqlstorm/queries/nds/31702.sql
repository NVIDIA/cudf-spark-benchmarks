
WITH  sales_summary AS (
    SELECT 
        c.c_customer_sk AS customer_key,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= (SELECT MAX(cd_dep_count) FROM customer_demographics WHERE cd_demo_sk = c.c_current_cdemo_sk)
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk
),
top_customers AS (
    SELECT
        customer_key,
        total_sales,
        order_count
    FROM 
        sales_summary
    WHERE 
        sales_rank <= 10
),
inventory_details AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory AS inv
    JOIN 
        item AS i ON inv.inv_item_sk = i.i_item_sk
    WHERE 
        inv.inv_quantity_on_hand IS NOT NULL
    GROUP BY 
        i.i_item_sk
),
store_sales_summary AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        store_sales AS ss
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    cust.customer_key,
    cust.total_sales,
    cust.order_count,
    inv.total_inventory,
    store.total_net_profit
FROM 
    top_customers AS cust
FULL OUTER JOIN 
    inventory_details AS inv ON cust.customer_key = inv.i_item_sk
FULL OUTER JOIN 
    store_sales_summary AS store ON inv.i_item_sk = store.ss_item_sk
WHERE 
    (cust.total_sales IS NOT NULL OR inv.total_inventory IS NOT NULL OR store.total_net_profit IS NOT NULL)
ORDER BY 
    cust.total_sales DESC NULLS LAST;
