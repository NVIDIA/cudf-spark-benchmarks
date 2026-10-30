
WITH Address_Components AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM
        customer_address
),
Demographic_Analysis AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS total_employed_dependents,
        SUM(cd_dep_college_count) AS total_college_dependents
    FROM
        customer_demographics cd
    JOIN
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd_demo_sk,
        cd_gender,
        cd_marital_status
),
Sales_Summary AS (
    SELECT
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    GROUP BY
        ws_bill_cdemo_sk
),
Final_Benchmark AS (
    SELECT
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country,
        d.cd_gender,
        d.cd_marital_status,
        d.customer_count,
        d.total_dependents,
        d.total_employed_dependents,
        d.total_college_dependents,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_profit, 0) AS total_profit
    FROM 
        Address_Components a
    JOIN
        Demographic_Analysis d ON a.ca_address_sk = d.cd_demo_sk
    LEFT JOIN
        Sales_Summary s ON d.cd_demo_sk = s.ws_bill_cdemo_sk
)
SELECT
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    cd_gender,
    cd_marital_status,
    customer_count,
    total_dependents,
    total_employed_dependents,
    total_college_dependents,
    total_sales,
    total_profit,
    CASE
        WHEN total_sales > 50000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 20000 AND 50000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM
    Final_Benchmark
ORDER BY
    total_sales DESC
LIMIT 100;
