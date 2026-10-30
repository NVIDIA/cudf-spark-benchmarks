
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        c.c_customer_id, ca.ca_city
),
ShippingDetails AS (
    SELECT 
        sm.sm_carrier,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_ship_cost) AS total_shipping_cost
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_carrier
)
SELECT 
    ss.c_customer_id,
    ss.ca_city,
    ss.total_sales,
    ss.order_count,
    ss.average_profit,
    sd.sm_carrier,
    sd.order_count AS shipping_order_count,
    sd.total_shipping_cost
FROM 
    SalesSummary ss
LEFT JOIN 
    ShippingDetails sd ON ss.order_count = sd.order_count
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
