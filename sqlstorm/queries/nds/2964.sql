
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_bill_customer_sk
),
CustomerReturnStats AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
CustomerProfile AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FinalReport AS (
    SELECT
        cp.c_customer_sk,
        cp.ca_city,
        cp.ca_state,
        cp.cd_gender,
        cp.cd_marital_status,
        cp.cd_education_status,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(rs.sales_rank, 0) AS sales_rank,
        COALESCE(rts.total_returns, 0) AS total_returns,
        COALESCE(rts.total_return_amt, 0) AS total_return_amt
    FROM
        CustomerProfile cp
    LEFT JOIN RankedSales rs ON cp.c_customer_sk = rs.ws_bill_customer_sk
    LEFT JOIN CustomerReturnStats rts ON cp.c_customer_sk = rts.sr_customer_sk
    WHERE
        UPPER(cp.cd_gender) = 'F'
        OR (cp.cd_marital_status = 'M' AND rs.total_sales > 5000)
)
SELECT
    *,
    CASE 
        WHEN total_sales = 0 AND total_returns > 0 THEN 'High Return Rate'
        WHEN total_sales > 5000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM
    FinalReport
WHERE
    total_sales IS NOT NULL
ORDER BY
    total_sales DESC,
    total_returns ASC;
