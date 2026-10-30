
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        d.d_year,
        SUM(ss.ss_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_company_id = w.w_warehouse_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        w.w_warehouse_id, d.d_year
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year < 1980
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
promotion_summary AS (
    SELECT 
        p.p_promo_id,
        COUNT(ws.ws_order_number) AS promo_orders,
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    ss.w_warehouse_id,
    ss.d_year,
    ss.total_sales,
    ss.total_quantity,
    ss.avg_net_profit,
    cs.order_count AS customer_order_count,
    ps.promo_orders,
    ps.promo_sales
FROM 
    sales_summary ss
LEFT JOIN 
    customer_summary cs ON ss.total_transactions = cs.order_count
LEFT JOIN 
    promotion_summary ps ON ss.total_sales > ps.promo_sales
ORDER BY 
    ss.d_year, ss.total_sales DESC;
