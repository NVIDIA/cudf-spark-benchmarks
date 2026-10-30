
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_item_sk) AS unique_items_sold
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        customer.c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_dep_count,
        cd_credit_rating,
        income_band.ib_lower_bound,
        income_band.ib_upper_bound
    FROM 
        customer
    JOIN 
        customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    LEFT JOIN 
        household_demographics ON household_demographics.hd_demo_sk = customer.c_current_hdemo_sk
    LEFT JOIN 
        income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
),
AggregatedData AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count,
        cd.cd_credit_rating,
        cd.ib_lower_bound,
        cd.ib_upper_bound,
        sd.total_profit,
        sd.total_orders,
        sd.unique_items_sold
    FROM 
        CustomerDemographics cd
    JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(total_profit) AS avg_profit,
    SUM(total_orders) AS total_orders,
    AVG(unique_items_sold) AS avg_unique_items_sold
FROM 
    AggregatedData
GROUP BY 
    cd_gender, 
    cd_marital_status
ORDER BY 
    cd_gender, 
    cd_marital_status;
