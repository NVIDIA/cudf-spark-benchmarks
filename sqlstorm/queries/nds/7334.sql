
WITH SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit,
        CAST(d_date AS DATE) AS sale_date,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year = 2023
    GROUP BY 
        ws_sold_date_sk, ws_item_sk, d_date
),
TopItems AS (
    SELECT 
        ws_item_sk, 
        total_quantity_sold,
        total_sales,
        total_net_profit,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM 
        SalesSummary
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    t.total_quantity_sold,
    t.total_sales,
    t.total_net_profit,
    t.rank,
    ca.ca_city,
    ca.ca_state,
    c.c_first_name,
    c.c_last_name
FROM 
    TopItems t
JOIN 
    item i ON t.ws_item_sk = i.i_item_sk
JOIN 
    store_sales ss ON t.ws_item_sk = ss.ss_item_sk
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    t.rank <= 10
ORDER BY 
    t.total_net_profit DESC;
