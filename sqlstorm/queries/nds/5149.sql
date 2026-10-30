
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS average_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        ss.ws_item_sk AS ss_item_sk,
        ss.total_quantity_sold,
        ss.total_sales,
        ss.total_orders,
        ss.average_net_profit,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    WHERE 
        ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
    ORDER BY 
        ss.total_sales DESC
    LIMIT 10
)
SELECT 
    ts.ss_item_sk,
    ts.total_quantity_sold,
    ts.total_sales,
    ts.total_orders,
    ts.average_net_profit,
    ts.i_item_desc,
    ts.i_brand,
    ts.i_category,
    ca.ca_city,
    ca.ca_state
FROM 
    top_sales ts
JOIN 
    customer_address ca ON ts.ss_item_sk = ca.ca_address_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
ORDER BY 
    ts.average_net_profit DESC;
