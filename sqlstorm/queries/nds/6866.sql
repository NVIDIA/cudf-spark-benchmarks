
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items,
        AVG(ws.ws_net_paid) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        d.d_year,
        d.d_month_seq
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, d.d_year, d.d_month_seq
),
customer_ranking AS (
    SELECT 
        cst.*, 
        RANK() OVER (PARTITION BY d_year ORDER BY total_spent DESC) AS rank_by_spending
    FROM 
        sales_summary cst
)
SELECT 
    cr.c_customer_id,
    cr.total_orders,
    cr.total_spent,
    cr.unique_items,
    cr.avg_order_value,
    cr.cd_gender,
    cr.cd_marital_status,
    cr.cd_education_status,
    cr.rank_by_spending
FROM 
    customer_ranking cr
WHERE 
    cr.rank_by_spending <= 10
ORDER BY 
    cr.total_spent DESC, cr.c_customer_id;
