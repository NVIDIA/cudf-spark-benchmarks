
WITH SalesData AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
        MAX(ws.ws_net_profit) AS max_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        w.w_warehouse_name, d.d_year, d.d_month_seq
),
PromotionData AS (
    SELECT 
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_name
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING 
        COUNT(ws.ws_order_number) > 10
),
FinalReport AS (
    SELECT 
        sd.w_warehouse_name,
        sd.d_year,
        sd.d_month_seq,
        sd.total_sales,
        pd.promo_order_count,
        cs.total_orders AS customer_order_count,
        cs.total_spent,
        sd.avg_net_paid,
        sd.max_profit
    FROM 
        SalesData sd
    LEFT JOIN 
        PromotionData pd ON sd.d_year = pd.promo_order_count
    LEFT JOIN 
        CustomerStats cs ON sd.total_orders = cs.total_orders
)
SELECT 
    *,
    (CASE 
        WHEN total_sales IS NOT NULL THEN 'Sales Data Available'
        ELSE 'No Sales Data'
    END) AS sales_data_status
FROM 
    FinalReport
ORDER BY 
    d_year DESC, d_month_seq DESC, total_sales DESC;
