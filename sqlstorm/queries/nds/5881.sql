
WITH sales_summary AS (
    SELECT 
        ws.ws_ship_mode_sk,
        sm.sm_type AS shipping_method,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        DENSE_RANK() OVER (PARTITION BY sm.sm_type ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rank_within_shipment
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_moy BETWEEN 1 AND 3
    GROUP BY 
        ws.ws_ship_mode_sk, sm.sm_type
),
top_shipping_methods AS (
    SELECT 
        shipping_method,
        total_orders,
        total_sales,
        total_discount,
        avg_sales_price
    FROM 
        sales_summary
    WHERE 
        rank_within_shipment <= 5
)
SELECT 
    shipping_method,
    total_orders,
    total_sales,
    total_discount,
    avg_sales_price,
    (total_sales - total_discount) AS net_sales
FROM 
    top_shipping_methods
ORDER BY 
    total_sales DESC;
