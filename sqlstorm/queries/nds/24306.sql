
WITH RankedReturns AS (
    SELECT
        cr_returning_customer_sk,
        cr_item_sk,
        cr_return_quantity,
        cr_return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY cr_item_sk ORDER BY cr_return_quantity DESC) AS rn
    FROM
        catalog_returns
    WHERE
        cr_return_quantity IS NOT NULL AND cr_return_amt_inc_tax > 0
),
CustomerShipping AS (
    SELECT
        ws_ship_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold
    FROM
        web_sales
    WHERE
        ws_ship_date_sk IS NOT NULL
    GROUP BY
        ws_ship_customer_sk, ws_item_sk
),
HighReturnCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT rr.cr_returning_customer_sk) AS return_count,
        COALESCE(AVG(rr.cr_return_amt_inc_tax), 0) AS avg_return_amt
    FROM
        customer c
    LEFT JOIN
        RankedReturns rr ON c.c_customer_sk = rr.cr_returning_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING
        COUNT(DISTINCT rr.cr_returning_customer_sk) > 5
),
SalesSummary AS (
    SELECT
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        cs_bill_customer_sk
),
CombinedData AS (
    SELECT
        hrc.c_customer_sk,
        hrc.c_first_name,
        hrc.c_last_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        hrc.return_count,
        hrc.avg_return_amt
    FROM
        HighReturnCustomers hrc
    LEFT JOIN
        SalesSummary ss ON hrc.c_customer_sk = ss.cs_bill_customer_sk
),
FinalData AS (
    SELECT
        *,
        CASE
            WHEN total_sales > 1000 THEN 'High Value'
            WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        CASE 
            WHEN return_count IS NULL THEN 'No Returns'
            WHEN return_count > 10 THEN 'Frequent Returner'
            ELSE 'Occasional Returner'
        END AS return_behavior
    FROM
        CombinedData
)
SELECT
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_sales,
    f.return_count,
    f.avg_return_amt,
    f.customer_value,
    f.return_behavior
FROM
    FinalData f
WHERE
    f.total_sales IS NOT NULL AND (f.customer_value != 'Low Value' OR f.return_behavior='Frequent Returner')
ORDER BY
    f.total_sales DESC, f.return_count ASC
LIMIT 100;
