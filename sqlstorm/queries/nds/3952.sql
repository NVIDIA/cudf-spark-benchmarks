
WITH MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cd.cd_demo_sk,
    cd.cd_gender,
    SUM(ms.total_sales) AS total_sales,
    COALESCE(SUM(cr.total_returned), 0) AS total_returned,
    (SUM(ms.total_sales) - COALESCE(SUM(cr.total_returned), 0)) AS net_sales,
    COUNT(DISTINCT ms.order_count) AS unique_orders,
    COUNT(DISTINCT CASE 
        WHEN ms.total_sales > 1000 THEN ms.d_month_seq 
        END) AS high_value_months,
    DENSE_RANK() OVER (ORDER BY SUM(ms.total_sales) DESC) AS sales_rank
FROM 
    CustomerDemographics cd
LEFT JOIN 
    MonthlySales ms ON cd.cd_demo_sk = ms.d_month_seq
LEFT JOIN 
    CustomerReturns cr ON cd.cd_demo_sk = cr.sr_customer_sk
GROUP BY 
    cd.cd_demo_sk, cd.cd_gender
HAVING 
    SUM(ms.total_sales) > 5000 OR COALESCE(SUM(cr.total_returned), 0) > 1000
ORDER BY 
    net_sales DESC;
