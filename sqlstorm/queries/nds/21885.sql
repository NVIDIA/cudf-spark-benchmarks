
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) as rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid IS NOT NULL
),
price_analysis AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        CASE 
            WHEN i.i_current_price <= 50 THEN 'Low'
            WHEN i.i_current_price BETWEEN 51 AND 150 THEN 'Medium'
            WHEN i.i_current_price > 150 THEN 'High'
            ELSE 'Undefined'
        END AS price_category
    FROM 
        item i
),
sales_summary AS (
    SELECT 
        coh.ca_country,
        SUM(CASE WHEN ws.ws_ship_date_sk = 20210101 THEN ws.ws_net_paid ELSE 0 END) AS specific_date_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    LEFT JOIN 
        customer_address coh ON ws.ws_bill_addr_sk = coh.ca_address_sk
    GROUP BY 
        coh.ca_country
)
SELECT 
    ps.price_category,
    s.ca_country,
    s.total_orders,
    s.specific_date_sales,
    s.avg_net_profit,
    r.ws_item_sk,
    r.ws_order_number,
    r.ws_net_paid
FROM 
    sales_summary s
JOIN 
    price_analysis ps ON ps.i_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'AIR'))
JOIN 
    ranked_sales r ON r.ws_item_sk = ps.i_item_sk
WHERE 
    s.specific_date_sales IS NOT NULL
    AND (s.total_orders > 10 OR s.avg_net_profit > 50)
    AND r.rnk <= 3
ORDER BY 
    ps.price_category, s.ca_country, r.ws_net_paid DESC;
