WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
ReturnInfo AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        CASE
            WHEN SUM(sr_return_quantity) IS NULL THEN 'No Returns'
            WHEN SUM(sr_return_quantity) > 0 THEN 'Returns Made'
            ELSE 'Return Value Not Available'
        END AS return_status
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
)
SELECT
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.return_count, 0) AS return_count,
    COALESCE(r.total_return_value, 0.00) AS total_return_value,
    rs.total_sales,
    CASE
        WHEN rs.sales_rank IS NULL THEN 'No Sales'
        WHEN rs.total_sales > 1000 THEN 'Top Seller'
        ELSE 'Ordinary Seller'
    END AS sales_performance
FROM
    CustomerDetails cd
LEFT JOIN
    ReturnInfo r ON cd.c_customer_sk = r.sr_customer_sk
LEFT JOIN
    RankedSales rs ON rs.ws_item_sk = cd.c_customer_sk  
WHERE
    (cd.cd_purchase_estimate > 500 OR r.return_count > 5)
    AND (cd.cd_gender = 'M' AND cd.cd_marital_status IS NOT NULL)
ORDER BY
    cd.cd_purchase_estimate DESC,
    total_return_value ASC,
    sales_performance DESC;