
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales AS ws
    LEFT JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_net_paid,
        sd.total_orders,
        sd.rank
    FROM 
        SalesData AS sd
    WHERE 
        sd.rank <= 5
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(ts.total_net_paid) AS city_total_net_sales,
    AVG(ts.total_orders) AS avg_orders_per_item,
    COUNT(DISTINCT ts.ws_item_sk) AS unique_item_count
FROM 
    TopSales AS ts
JOIN 
    customer AS c ON ts.ws_item_sk = c.c_customer_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(ts.total_net_paid) > (SELECT AVG(total_net_paid) FROM SalesData)
ORDER BY 
    city_total_net_sales DESC;
