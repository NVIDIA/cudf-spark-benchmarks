
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_sales,
        DENSE_RANK() OVER (ORDER BY sales.total_sales DESC) AS dense_rank
    FROM 
        sales_summary sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.sales_rank <= 10
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    cs.order_count,
    cs.total_profit,
    ai.ca_city,
    ai.ca_state,
    ai.customer_count,
    CASE 
        WHEN cs.total_profit IS NULL THEN 'No Profit Data'
        ELSE CAST(cs.total_profit AS STRING)
    END AS profit_info
FROM 
    top_items ti
JOIN 
    customer_stats cs ON ti.total_sales > 1000
LEFT JOIN 
    address_info ai ON cs.c_customer_sk IN (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = cs.c_customer_sk)
WHERE 
    ai.customer_count > 5
ORDER BY 
    ti.total_sales DESC, cs.order_count DESC;
