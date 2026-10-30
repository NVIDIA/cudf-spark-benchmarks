
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS total_profit,
        d_month_seq
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year = 2023 AND d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        ws_bill_customer_sk, d_month_seq
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        hd_income_band_sk
    FROM 
        customer_demographics
    JOIN 
        household_demographics ON cd_demo_sk = hd_demo_sk
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    SUM(sd.total_quantity) AS total_quantity_sold,
    SUM(sd.total_sales) AS total_sales_amount,
    AVG(sd.total_profit) AS average_profit,
    COUNT(DISTINCT sd.ws_bill_customer_sk) AS unique_customers,
    ib.ib_lower_bound AS income_band_lower,
    ib.ib_upper_bound AS income_band_upper
FROM 
    SalesData sd
JOIN 
    Demographics d ON sd.ws_bill_customer_sk = d.cd_demo_sk
JOIN 
    income_band ib ON d.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY 
    d.cd_gender,
    d.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
