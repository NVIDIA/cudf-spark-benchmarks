
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        c.c_customer_id, cd.cd_gender, hd.hd_income_band_sk
),
ranked_sales AS (
    SELECT 
        s.*,
        RANK() OVER (PARTITION BY s.hd_income_band_sk ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        sales_summary s
)
SELECT 
    r.c_customer_id, 
    r.cd_gender, 
    r.hd_income_band_sk, 
    r.total_quantity, 
    r.total_sales, 
    r.total_orders
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.hd_income_band_sk, r.total_sales DESC;
