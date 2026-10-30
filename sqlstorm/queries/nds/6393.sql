
WITH CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid) AS avg_order_value,
        MIN(ws.ws_sold_date_sk) AS first_order_date,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
OrderDates AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT cm.c_customer_sk) AS active_customers,
        SUM(cm.total_orders) AS total_orders,
        SUM(cm.total_profit) AS total_profit,
        AVG(cm.avg_order_value) AS avg_order_value
    FROM 
        CustomerMetrics cm
    JOIN 
        date_dim d ON d.d_date_sk IN (cm.first_order_date, cm.last_order_date)
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    od.d_year,
    od.d_month_seq,
    od.active_customers,
    od.total_orders,
    od.total_profit,
    od.avg_order_value,
    RANK() OVER (ORDER BY od.total_profit DESC) AS profit_rank,
    RANK() OVER (ORDER BY od.active_customers DESC) AS customer_rank
FROM 
    OrderDates od
WHERE 
    od.d_year = 2023
ORDER BY 
    od.total_profit DESC;
