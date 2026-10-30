
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_paid_inc_tax,
        dd.d_year,
        dd.d_month_seq,
        sm.sm_type,
        c.c_customer_id,
        ca.ca_city,
        ra.r_reason_desc
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_returns sr ON ws.ws_order_number = sr.sr_ticket_number AND ws.ws_item_sk = sr.sr_item_sk
    LEFT JOIN 
        reason ra ON sr.sr_reason_sk = ra.r_reason_sk
),
ranked_sales AS (
    SELECT 
        sd.*, 
        RANK() OVER (PARTITION BY sd.c_customer_id ORDER BY sd.ws_net_paid DESC) as rank_sales
    FROM 
        sales_data sd
    WHERE 
        sd.ws_net_paid > 0
)
SELECT 
    r.c_customer_id,
    r.ca_city,
    SUM(r.ws_net_paid) AS total_net_paid,
    AVG(r.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT r.ws_order_number) AS total_orders,
    MAX(r.ws_quantity) AS max_item_quantity,
    COUNT(r.r_reason_desc) AS total_returns,
    CASE 
        WHEN SUM(r.ws_net_paid) > 10000 THEN 'High Value'
        WHEN SUM(r.ws_net_paid) BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    ranked_sales r
WHERE 
    r.rank_sales <= 5
GROUP BY 
    r.c_customer_id, r.ca_city
ORDER BY 
    total_net_paid DESC
LIMIT 100;
