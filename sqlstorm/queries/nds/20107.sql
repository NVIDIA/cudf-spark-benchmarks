
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_ship_date_sk BETWEEN 1 AND 10000
    GROUP BY
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        (SELECT COUNT(*) 
         FROM store_sales ss 
         WHERE ss.ss_customer_sk = c.c_customer_sk) AS store_sales_count,
        (SELECT COUNT(*) 
         FROM web_sales ws 
         WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS web_sales_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    cd.*,
    COALESCE(rs.total_sales, 0) AS total_web_sales,
    CASE 
        WHEN cd.cd_gender = 'F' AND cd.cd_marital_status = 'M' THEN 'Married Female'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        WHEN cd.cd_gender = 'M' AND cd.cd_marital_status = 'M' THEN 'Married Male'
        ELSE 'Male'
    END AS gender_marital_category,
    (cd.store_sales_count + cd.web_sales_count) AS total_sales_count
FROM
    CustomerDetails cd
LEFT JOIN
    RankedSales rs ON cd.c_customer_sk = rs.ws_bill_customer_sk AND rs.sales_rank = 1
WHERE
    (cd.cd_purchase_estimate > 1000 OR cd.cd_gender IS NULL)
    AND (cd.store_sales_count > 5 OR cd.web_sales_count IS NOT NULL)
ORDER BY
    total_web_sales DESC, 
    cd.c_last_name ASC NULLS LAST
LIMIT 50;
