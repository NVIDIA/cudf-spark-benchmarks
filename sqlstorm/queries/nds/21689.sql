WITH RankSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS row_num
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
FilteredSales AS (
    SELECT 
        ws_item_sk, 
        total_sales 
    FROM 
        RankSales 
    WHERE 
        sales_rank <= 10 
        OR total_sales IS NULL
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        CASE 
            WHEN cd_dep_count IS NULL THEN 0 
            ELSE cd_dep_count 
        END AS dep_count
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 1000
)
SELECT 
    ca_state,
    SUM(FS.total_sales) AS sum_sales,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    AVG(CD.dep_count) AS avg_dependent_count
FROM 
    customer_address CA 
LEFT JOIN 
    customer C ON CA.ca_address_sk = C.c_current_addr_sk
LEFT JOIN 
    FilteredSales FS ON FS.ws_item_sk = C.c_current_cdemo_sk
LEFT JOIN 
    CustomerDemographics CD ON CD.cd_demo_sk = C.c_current_cdemo_sk
WHERE 
    CA.ca_country = 'USA' 
    AND (CD.cd_gender = 'M' OR CD.cd_gender IS NULL)
GROUP BY 
    CA.ca_state
HAVING 
    SUM(FS.total_sales) IS NOT NULL
    AND COUNT(CAST(FS.total_sales AS INTEGER)) > 5
ORDER BY 
    CA.ca_state DESC
LIMIT 20;