
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit,
        cd.cd_gender AS customer_gender,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper
    FROM 
        web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, cd.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
),
ranked_sales AS (
    SELECT 
        sales_year, 
        sales_month, 
        total_quantity, 
        total_sales, 
        average_profit,
        customer_gender,
        income_lower,
        income_upper,
        RANK() OVER (PARTITION BY sales_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    sales_year,
    sales_month,
    total_quantity,
    total_sales,
    average_profit,
    customer_gender,
    income_lower,
    income_upper
FROM 
    ranked_sales
WHERE 
    sales_rank <= 5
ORDER BY 
    sales_year, 
    sales_month, 
    total_sales DESC;
