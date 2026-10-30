
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        i.i_item_desc,
        sm.sm_type,
        c.c_first_name,
        c.c_last_name
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year = 2023
        AND ws.ws_net_paid > 100
),
aggregated_sales AS (
    SELECT 
        d_year,
        d_month_seq,
        d_quarter_seq,
        i_item_desc,
        sm_type,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        sales_data
    GROUP BY 
        d_year, d_month_seq, d_quarter_seq, i_item_desc, sm_type
)
SELECT 
    d_year,
    d_month_seq,
    d_quarter_seq,
    i_item_desc,
    sm_type,
    total_orders,
    total_quantity,
    total_net_paid,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_paid DESC) AS sales_rank
FROM 
    aggregated_sales
WHERE 
    total_orders > 5
ORDER BY 
    d_year, d_month_seq, sales_rank;
