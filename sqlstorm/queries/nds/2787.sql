
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
date_summary AS (
    SELECT 
        dd.d_date_sk,
        dd.d_year,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        date_dim dd
    JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        dd.d_date_sk, dd.d_year
),
income_ranges AS (
    SELECT 
        ib.ib_income_band_sk,
        CASE
            WHEN ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL THEN 'Undefined'
            ELSE CONCAT(ib.ib_lower_bound, ' - ', ib.ib_upper_bound)
        END AS income_range
    FROM 
        income_band ib
)
SELECT 
    cs.c_customer_id,
    cs.total_quantity,
    cs.total_sales,
    ds.d_year,
    ds.total_net_paid,
    ds.avg_sales_price,
    ir.income_range
FROM 
    customer_summary cs
JOIN 
    date_summary ds ON cs.c_customer_sk = ds.d_date_sk 
LEFT JOIN 
    household_demographics hd ON cs.c_customer_sk = hd.hd_demo_sk 
LEFT JOIN 
    income_ranges ir ON hd.hd_income_band_sk = ir.ib_income_band_sk
WHERE 
    cs.sales_rank <= 10 
    AND ds.total_net_paid > 1000
ORDER BY 
    cs.total_sales DESC, 
    ds.d_year DESC;
