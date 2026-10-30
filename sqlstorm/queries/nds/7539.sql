
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_paid) AS total_net_paid, 
        SUM(ws.ws_ext_tax) AS total_tax,
        DENSE_RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_moy BETWEEN 1 AND 3
    GROUP BY 
        ws.ws_item_sk, ws.ws_sold_date_sk
),
high_performance_items AS (
    SELECT 
        item.i_item_id, 
        item.i_item_desc, 
        item.i_current_price,
        sd.total_quantity, 
        sd.total_net_paid, 
        sd.total_tax
    FROM 
        item 
    JOIN 
        sales_data sd ON item.i_item_sk = sd.ws_item_sk
    WHERE 
        sd.sales_rank <= 10
)
SELECT 
    hpi.i_item_id, 
    hpi.i_item_desc, 
    hpi.i_current_price, 
    hpi.total_quantity, 
    hpi.total_net_paid, 
    hpi.total_tax,
    ca.ca_city, 
    ca.ca_state 
FROM 
    high_performance_items hpi 
JOIN 
    customer c ON hpi.total_quantity = (SELECT MAX(hpi2.total_quantity) FROM high_performance_items hpi2)
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY 
    hpi.total_net_paid DESC;
