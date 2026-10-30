WITH sales_summary AS (
    SELECT 
        d.d_year AS transaction_year,
        d.d_month_seq AS transaction_month,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'M' 
        AND cd.cd_marital_status = 'M' 
        AND d.d_year BETWEEN 1998 AND 2001
    GROUP BY 
        d.d_year, d.d_month_seq
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_sales_price) AS warehouse_total_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
promotion_analysis AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(ws.ws_order_number) AS promo_order_count
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name
),
final_summary AS (
    SELECT 
        ss.transaction_year,
        ss.transaction_month,
        ss.total_sales,
        ss.total_orders,
        ss.unique_customers,
        ws.warehouse_total_sales,
        pa.promo_order_count,
        pa.total_discount
    FROM 
        sales_summary ss
    LEFT JOIN 
        warehouse_sales ws ON ss.transaction_year = EXTRACT(YEAR FROM cast('2002-10-01' as date)) 
    LEFT JOIN 
        promotion_analysis pa ON ss.transaction_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
)
SELECT 
    transaction_year,
    transaction_month,
    total_sales,
    total_orders,
    unique_customers,
    warehouse_total_sales,
    promo_order_count,
    total_discount
FROM 
    final_summary
ORDER BY 
    transaction_year, transaction_month;