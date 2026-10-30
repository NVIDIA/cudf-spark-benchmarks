
WITH  SalesHistory AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_month_seq BETWEEN 1 AND 12 LIMIT 1)
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_month_seq BETWEEN 1 AND 12 ORDER BY d_date_sk DESC LIMIT 1)
    GROUP BY
        ws_item_sk
),
HighVolumeSales AS (
    SELECT
        sh.ws_item_sk,
        sh.total_sales,
        sh.order_count,
        ROW_NUMBER() OVER (ORDER BY sh.total_sales DESC) AS volume_rank
    FROM
        SalesHistory sh
    WHERE
        sh.rank <= 5
),
CustomerReturnStats AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_qty
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
FinalReport AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(hv.total_sales, 0) AS total_sales,
        COALESCE(crs.return_count, 0) AS total_returns,
        COALESCE(crs.total_return_amt, 0) AS total_return_amount,
        COALESCE(crs.total_return_qty, 0) AS total_return_quantity,
        CASE WHEN crs.total_return_amt > 0 THEN (COALESCE(hv.total_sales, 0) - COALESCE(crs.total_return_amt, 0)) ELSE COALESCE(hv.total_sales, 0) END AS net_sales_after_returns
    FROM
        customer c
    LEFT JOIN
        HighVolumeSales hv ON c.c_customer_sk = hv.ws_item_sk
    LEFT JOIN
        CustomerReturnStats crs ON c.c_customer_sk = crs.sr_customer_sk
)
SELECT
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.total_sales,
    f.total_returns,
    f.total_return_amount,
    f.total_return_quantity,
    CASE WHEN f.net_sales_after_returns < 0 THEN 'Negative Sales' ELSE 'Positive Sales' END AS sales_status
FROM
    FinalReport f
WHERE
    f.total_sales > 1000 OR f.total_returns > 0
ORDER BY
    f.total_sales DESC, f.total_returns DESC;
