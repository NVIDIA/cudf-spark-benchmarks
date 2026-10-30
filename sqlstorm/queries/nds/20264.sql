
WITH RankedReturns AS (
    SELECT
        sr_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM
        store_returns
    WHERE
        sr_return_quantity IS NOT NULL
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        COALESCE(hd.hd_dep_count, 0) AS dep_count,
        COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count
    FROM
        customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        c.c_birth_year IS NOT NULL AND c.c_birth_month IS NOT NULL
),
FinalSales AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales AS ws
    WHERE
        ws.ws_sales_price < 100.00
    GROUP BY
        ws.ws_bill_customer_sk
),
ReturnedCustomers AS (
    SELECT
        r.r_customer_sk,
        SUM(r.r_return_amount) AS total_returned,
        COUNT(DISTINCT r.r_order_number) AS return_count
    FROM (
        SELECT
            wr_returning_customer_sk AS r_customer_sk,
            wr_return_amt AS r_return_amount,
            wr_order_number AS r_order_number
        FROM
            web_returns
        UNION ALL
        SELECT
            cr_returning_customer_sk AS r_customer_sk,
            cr_return_amount AS r_return_amount,
            cr_order_number AS r_order_number
        FROM
            catalog_returns
    ) AS r
    GROUP BY
        r.r_customer_sk
)
SELECT
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_marital_status,
    cd.dep_count,
    cd.vehicle_count,
    COALESCE(rs.return_count, 0) AS total_returns,
    COALESCE(fs.total_sales, 0) AS total_sales,
    fs.order_count,
    CASE
        WHEN COALESCE(fs.total_sales, 0) = 0 THEN 'No Sales'
        WHEN COALESCE(rs.return_count, 0) > 0 AND COALESCE(fs.total_sales, 0) > 0 THEN 'Returned Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM
    CustomerDetails AS cd
LEFT JOIN FinalSales AS fs ON cd.c_customer_sk = fs.ws_bill_customer_sk
LEFT JOIN ReturnedCustomers AS rs ON cd.c_customer_sk = rs.r_customer_sk
WHERE
    (cd.dep_count + cd.vehicle_count) > 0
ORDER BY
    customer_type DESC,
    cd.c_last_name ASC,
    cd.c_first_name ASC;
