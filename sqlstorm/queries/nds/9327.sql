
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        p.p_promo_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, d.d_quarter_seq, p.p_promo_name, ws.ws_bill_customer_sk
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sws.total_sales) AS total_sales,
        SUM(sws.total_quantity) AS total_quantity,
        COUNT(DISTINCT sws.total_orders) AS order_count
    FROM 
        sales_summary sws
    JOIN 
        customer c ON c.c_customer_sk = sws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_sales,
    cs.total_quantity,
    cs.order_count,
    RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
FROM 
    customer_summary cs
WHERE 
    cs.total_sales > 10000
ORDER BY 
    cs.total_sales DESC, cs.total_quantity DESC;
