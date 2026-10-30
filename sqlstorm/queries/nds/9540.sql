
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(ws.ws_item_sk) AS total_items,
        AVG(ws.ws_net_paid) AS avg_order_value,
        MAX(ws.ws_net_paid) AS max_order_value,
        MIN(ws.ws_net_paid) AS min_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND
        c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_id
),
customer_demographics AS (
    SELECT 
        cd.cd_gender,
        SUM(ss.total_sales) AS total_sales_by_gender,
        COUNT(DISTINCT ss.c_customer_id) AS customer_count
    FROM 
        sales_summary ss
    JOIN 
        customer_demographics cd ON ss.c_customer_id IN (
            SELECT c.c_customer_id 
            FROM customer c 
            WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM customer))
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cd.cd_gender,
    cd.total_sales_by_gender,
    cd.customer_count,
    ROUND(cd.total_sales_by_gender / NULLIF(cd.customer_count, 0), 2) AS avg_sales_per_customer
FROM 
    customer_demographics cd
ORDER BY 
    cd.total_sales_by_gender DESC;
