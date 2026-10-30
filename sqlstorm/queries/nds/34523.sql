
WITH  SalesTrends AS (
    SELECT 
        d_year,
        SUM(ss_net_paid) AS total_sales
    FROM 
        store_sales
    JOIN 
        date_dim ON ss_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
    UNION ALL
    SELECT 
        d_year + 1, 
        SUM(ss_net_paid) AS total_sales
    FROM 
        store_sales
    JOIN 
        date_dim ON ss_sold_date_sk = d_date_sk
    WHERE 
        d_year <= (SELECT MAX(d_year) FROM date_dim)
    GROUP BY 
        d_year
),
QualifiedDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        CASE
            WHEN cd_purchase_estimate > 10000 THEN 'High Value'
            WHEN cd_purchase_estimate BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM 
        customer_demographics
    WHERE 
        cd_gender = 'F' AND cd_marital_status = 'M'
),
TopStores AS (
    SELECT 
        s_store_sk,
        s_store_name,
        SUM(ss_net_paid) AS total_store_sales
    FROM 
        store_sales
    JOIN 
        store ON ss_store_sk = s_store_sk
    GROUP BY 
        s_store_sk, s_store_name
    HAVING 
        SUM(ss_net_paid) > 200000
)
SELECT 
    sd.year_sales,
    qd.value_category,
    ts.total_store_sales,
    ROW_NUMBER() OVER (PARTITION BY qd.value_category ORDER BY ts.total_store_sales DESC) AS rank
FROM 
    (SELECT 
         d_year AS year_sales, 
         total_sales 
     FROM 
         SalesTrends) sd
JOIN 
    QualifiedDemographics qd ON 1=1
JOIN 
    TopStores ts ON 1=1
WHERE 
    ts.total_store_sales > (SELECT AVG(total_store_sales) FROM TopStores)
ORDER BY 
    sd.year_sales DESC, 
    rank;
