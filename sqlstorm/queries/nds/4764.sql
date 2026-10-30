
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        AVG(sr_return_amt_inc_tax) AS average_return_amt,
        DENSE_RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank_return
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
MonthlySales AS (
    SELECT 
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_year, d.d_month_seq
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.total_return_quantity,
        r.average_return_amt
    FROM 
        CustomerInfo c
    JOIN 
        RankedReturns r ON c.c_customer_sk = r.sr_customer_sk
    WHERE 
        r.rank_return <= 10
)
SELECT 
    t.year,
    t.month_seq,
    COALESCE(tc.c_first_name, 'N/A') AS customer_first_name,
    COALESCE(tc.c_last_name, 'N/A') AS customer_last_name,
    t.total_sales,
    t.total_profit,
    CASE 
        WHEN t.total_profit > (SELECT AVG(total_profit) FROM MonthlySales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS profit_performance,
    COUNT(tc.c_customer_sk) AS return_customers_count
FROM 
    MonthlySales t
LEFT JOIN 
    TopCustomers tc ON t.year IS NOT NULL
GROUP BY 
    t.year, t.month_seq, tc.c_first_name, tc.c_last_name, t.total_sales, t.total_profit
ORDER BY 
    t.year, t.month_seq;
