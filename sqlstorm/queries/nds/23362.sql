
WITH RankedSales AS (
    SELECT 
        ss_item_sk, 
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        DENSE_RANK() OVER(PARTITION BY ss_item_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
TopItems AS (
    SELECT 
        rs.ss_item_sk,
        rs.total_sales,
        rs.unique_customers,
        pi.i_product_name,
        pi.i_category
    FROM 
        RankedSales rs
    JOIN 
        item pi ON rs.ss_item_sk = pi.i_item_sk
    WHERE 
        rs.sales_rank <= 10
),
ReturningCustomers AS (
    SELECT 
        customer.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        sr_item_sk
    FROM 
        store_returns sr
    JOIN 
        customer ON sr.sr_customer_sk = customer.c_customer_sk
    GROUP BY 
        customer.c_customer_sk,
        sr_item_sk
    HAVING 
        COUNT(DISTINCT sr_ticket_number) > 1
),
SalesInfo AS (
    SELECT 
        ti.ss_item_sk,
        ti.total_sales,
        rc.return_count,
        rc.total_return_amount,
        (ti.total_sales - COALESCE(rc.total_return_amount, 0)) AS net_sales_incl_returns
    FROM 
        TopItems ti
    LEFT JOIN 
        ReturningCustomers rc ON ti.ss_item_sk = rc.sr_item_sk
),
FinalReport AS (
    SELECT 
        si.ss_item_sk,
        si.total_sales,
        si.return_count,
        si.net_sales_incl_returns,
        CASE
            WHEN si.return_count IS NULL THEN 'Never Returned'
            WHEN si.return_count > 5 THEN 'Frequent Returner'
            ELSE 'Rare Returner'
        END AS return_behavior
    FROM 
        SalesInfo si
)
SELECT 
    fr.ss_item_sk,
    fr.total_sales,
    fr.net_sales_incl_returns,
    fr.return_behavior,
    (SELECT COUNT(*) FROM store WHERE s_state = 'CA') AS ca_store_count,
    (SELECT COUNT(*) FROM customer_demographics WHERE cd_marital_status = 'M' AND cd_gender = 'F') AS female_married_count,
    (SELECT MAX(d_year) FROM date_dim WHERE d_dow = 1) AS latest_monday_year
FROM 
    FinalReport fr
WHERE 
    fr.net_sales_incl_returns > 0
ORDER BY 
    fr.total_sales DESC
LIMIT 20;
