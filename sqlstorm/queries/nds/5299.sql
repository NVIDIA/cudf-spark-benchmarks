
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 40000 AND 40030
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk, 
        ri.total_sales, 
        ri.total_orders,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM 
        RankedSales ri
    JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    WHERE 
        ri.sales_rank <= 10
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(ti.total_sales) AS city_sales,
    COUNT(ti.total_orders) AS order_count
FROM 
    TopItems ti
JOIN 
    store s ON s.s_store_sk = ti.ws_item_sk
JOIN 
    customer_address ca ON s.s_street_number = ca.ca_address_id
GROUP BY 
    ca.ca_city, 
    ca.ca_state
ORDER BY 
    city_sales DESC
LIMIT 5;
