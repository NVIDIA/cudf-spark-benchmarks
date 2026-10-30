
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_orders,
        rs.total_revenue
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 10
)
SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_orders,
    tsi.total_revenue,
    ca.ca_city,
    c.c_first_name,
    c.c_last_name
FROM 
    TopSellingItems tsi
JOIN 
    customer c ON c.c_customer_sk IN (
        SELECT DISTINCT ws.ws_ship_customer_sk
        FROM web_sales ws
        JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
        WHERE dd.d_year = 2023
    )
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY 
    tsi.total_revenue DESC;
