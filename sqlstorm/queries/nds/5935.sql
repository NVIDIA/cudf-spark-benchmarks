
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS average_profit
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        d.d_year,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN 
        date_dim d ON c.c_birth_year = d.d_year
),
FinalResults AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        sa.total_sales,
        sa.total_orders,
        sa.average_profit,
        ci.ib_lower_bound,
        ci.ib_upper_bound,
        ci.hd_buy_potential
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sa ON ci.c_customer_sk = sa.ws_bill_customer_sk
)
SELECT 
    cd_gender AS gender,
    cd_marital_status AS marital_status,
    cd_education_status AS education_status,
    COUNT(*) AS customer_count,
    SUM(total_sales) AS grand_total_sales,
    AVG(total_orders) AS avg_orders_per_customer,
    AVG(average_profit) AS avg_profit_per_customer 
FROM 
    FinalResults
WHERE 
    total_sales > 0
GROUP BY 
    cd_gender, cd_marital_status, cd_education_status
ORDER BY 
    grand_total_sales DESC
LIMIT 10;
