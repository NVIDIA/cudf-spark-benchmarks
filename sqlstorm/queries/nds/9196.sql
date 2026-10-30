
WITH sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        s.total_quantity,
        s.total_sales,
        s.total_discount,
        s.total_profit,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank,
        s.ws_item_sk
    FROM 
        item i
    JOIN 
        sales s ON i.i_item_sk = s.ws_item_sk
)
SELECT 
    t.sales_rank,
    t.i_item_id,
    t.i_product_name,
    t.total_quantity,
    t.total_sales,
    t.total_discount,
    t.total_profit,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers
FROM 
    top_items t
JOIN 
    web_sales ws ON t.ws_item_sk = ws.ws_item_sk
JOIN 
    customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE 
    t.sales_rank <= 10
GROUP BY 
    t.sales_rank, t.i_item_id, t.i_product_name, t.total_quantity, t.total_sales, t.total_discount, t.total_profit, ca.ca_city, ca.ca_state
ORDER BY 
    t.sales_rank;
