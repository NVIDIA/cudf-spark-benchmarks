
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk, d.d_year, d.d_month_seq, d.d_week_seq, 
        c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, hd.hd_income_band_sk
),
AggregatedData AS (
    SELECT 
        d_year,
        d_month_seq,
        d_week_seq,
        SUM(total_quantity) AS total_quantity,
        SUM(total_net_paid) AS total_net_paid,
        AVG(total_net_paid / NULLIF(order_count, 0)) AS avg_order_value,
        COUNT(*) AS customer_count,
        COUNT(DISTINCT c_current_cdemo_sk) AS unique_customers,
        SUM(CASE WHEN cd_gender = 'M' THEN total_quantity ELSE 0 END) AS male_quantity,
        SUM(CASE WHEN cd_gender = 'F' THEN total_quantity ELSE 0 END) AS female_quantity,
        hd_income_band_sk
    FROM 
        SalesData
    GROUP BY 
        d_year, d_month_seq, d_week_seq, hd_income_band_sk
)
SELECT 
    ad.d_year,
    ad.d_month_seq,
    ad.d_week_seq,
    ad.total_quantity,
    ad.total_net_paid,
    ad.avg_order_value,
    ad.customer_count,
    ad.unique_customers,
    ad.male_quantity,
    ad.female_quantity,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    AggregatedData ad
JOIN 
    income_band ib ON ad.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    ad.d_year, ad.d_month_seq, ad.d_week_seq;
