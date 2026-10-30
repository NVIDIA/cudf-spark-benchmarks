
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        dd.d_year,
        dd.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND cd.cd_gender = 'F'
),
total_sales AS (
    SELECT 
        r.ca_city,
        r.ca_state,
        SUM(r.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT r.ws_order_number) AS total_orders,
        COUNT(DISTINCT r.ws_item_sk) AS unique_items_sold,
        AVG(r.ws_sales_price) AS average_price,
        MAX(r.ws_sales_price) AS max_price,
        MIN(r.ws_sales_price) AS min_price
    FROM 
        ranked_sales r
    GROUP BY 
        r.ca_city, r.ca_state
)
SELECT 
    ts.ca_city,
    ts.ca_state,
    ts.total_net_paid,
    ts.total_orders,
    ts.unique_items_sold,
    ts.average_price,
    ts.max_price,
    ts.min_price,
    CASE 
        WHEN ts.total_net_paid IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    total_sales ts
WHERE 
    ts.total_orders > 0
ORDER BY 
    ts.total_net_paid DESC
LIMIT 10;
