
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sale_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesGenderHypothesis AS (
    SELECT 
        gd.cd_gender,
        CASE 
            WHEN SUM(rs.total_sales) IS NULL THEN 0
            ELSE SUM(rs.total_sales)
        END AS total_sales,
        COUNT(DISTINCT rs.ws_bill_customer_sk) AS customer_count,
        AVG(rs.total_sales) AS average_sales
    FROM 
        RankedSales rs
    JOIN CustomerDemographics gd ON rs.ws_bill_customer_sk = gd.c_customer_sk
    GROUP BY 
        gd.cd_gender
)
SELECT 
    g.cd_gender,
    g.total_sales,
    g.customer_count,
    g.average_sales,
    CASE 
        WHEN g.average_sales > 1000 THEN 'High'
        WHEN g.average_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    SalesGenderHypothesis g
ORDER BY 
    g.total_sales DESC
LIMIT 10;
