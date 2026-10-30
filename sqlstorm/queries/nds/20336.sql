
WITH RankedSales AS (
    SELECT
        cs_item_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(cs_order_number) AS order_count,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
    GROUP BY
        cs_item_sk
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COALESCE(cd_dep_count, 0) AS dep_count,
        CASE 
            WHEN cd_education_status IN ('High School', 'Some College') THEN 'Low Education'
            WHEN cd_education_status IN ('Bachelors', 'Masters') THEN 'High Education'
            ELSE 'Other'
        END AS education_band
    FROM
        customer_demographics
),
DistinctCustomers AS (
    SELECT
        DISTINCT c_customer_sk,
        dem.cd_gender,
        dem.cd_marital_status,
        dem.dep_count,
        dem.education_band
    FROM
        customer c
    LEFT JOIN 
        CustomerDemographics dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
    WHERE
        c.c_preferred_cust_flag = 'Y'
),
SalesInTopDemographics AS (
    SELECT
        ds.cd_gender,
        ds.education_band,
        SUM(rs.total_profit) AS sales_profit,
        COUNT(ds.c_customer_sk) AS total_customers
    FROM
        RankedSales rs
    JOIN
        store_sales ss ON rs.cs_item_sk = ss.ss_item_sk
    JOIN
        DistinctCustomers ds ON ss.ss_customer_sk = ds.c_customer_sk
    WHERE
        rs.profit_rank <= 10
    GROUP BY
        ds.cd_gender, ds.education_band
)
SELECT
    sd.cd_gender,
    sd.education_band,
    SUM(sd.sales_profit) AS total_sales_profit,
    COUNT(sd.total_customers) AS total_customers,
    ROUND(AVG(NULLIF(sd.sales_profit, 0) / NULLIF(sd.total_customers, 0)), 2) AS avg_profit_per_customer
FROM
    SalesInTopDemographics sd
GROUP BY
    sd.cd_gender, sd.education_band
ORDER BY
    total_sales_profit DESC,
    total_customers DESC;
