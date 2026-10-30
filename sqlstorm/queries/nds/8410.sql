
WITH sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_value,
        d_year,
        d_month_seq,
        c_current_cdemo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        h.hd_income_band_sk,
        ib.ib_upper_bound,
        ib.ib_lower_bound
    FROM 
        web_sales ws 
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
    JOIN 
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ws_item_sk, d_year, d_month_seq, c_current_cdemo_sk, cd_gender, cd_marital_status, cd_education_status, h.hd_income_band_sk, ib.ib_upper_bound, ib.ib_lower_bound
),
ranked_sales AS (
    SELECT 
        sd.*, 
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales_value DESC) AS sales_rank
    FROM 
        sales_data sd
)
SELECT 
    rs.d_year, 
    rs.d_month_seq, 
    rs.total_quantity_sold, 
    rs.total_sales_value, 
    rs.cd_gender, 
    rs.cd_marital_status, 
    rs.cd_education_status, 
    rs.ib_lower_bound, 
    rs.ib_upper_bound
FROM 
    ranked_sales rs
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.d_year, 
    rs.d_month_seq, 
    rs.total_sales_value DESC;
