
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid) AS avg_payment,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_addr_sk) AS distinct_addresses,
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        d.d_quarter_seq AS sales_quarter
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2022
    GROUP BY 
        c.c_customer_sk, d.d_year, d.d_month_seq, d.d_quarter_seq
),
address_summary AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        ca.ca_state AS customer_state,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, ca.ca_state
)
SELECT 
    ss.customer_id,
    ss.total_profit,
    ss.avg_payment,
    ss.total_orders,
    asu.address_count,
    asu.customer_state,
    ss.sales_year,
    ss.sales_month,
    ss.sales_quarter
FROM 
    sales_summary ss
JOIN 
    address_summary asu ON ss.customer_id = asu.customer_id
ORDER BY 
    ss.total_profit DESC, ss.avg_payment DESC
LIMIT 100;
