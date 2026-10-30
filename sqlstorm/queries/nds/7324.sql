
WITH sales_data AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales, 
        SUM(ws_net_profit) AS total_profit, 
        d_year,
        cd_gender,
        ib_income_band_sk
    FROM web_sales 
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    JOIN customer ON ws_bill_customer_sk = c_customer_sk
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN household_demographics ON cd_demo_sk = hd_demo_sk
    JOIN income_band ON hd_income_band_sk = ib_income_band_sk
    WHERE d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws_bill_customer_sk, 
        d_year, 
        cd_gender, 
        ib_income_band_sk
), 
ranked_sales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
    FROM sales_data
)
SELECT 
    d_year,
    cd_gender,
    ib_income_band_sk,
    COUNT(ws_bill_customer_sk) AS customer_count,
    SUM(total_quantity) AS total_quantity,
    SUM(total_sales) AS total_sales,
    SUM(total_profit) AS total_profit
FROM ranked_sales
WHERE profit_rank <= 10
GROUP BY d_year, cd_gender, ib_income_band_sk
ORDER BY d_year, total_profit DESC;
