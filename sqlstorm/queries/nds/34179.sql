
WITH  CustomerSalesCTE AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS sale_rank
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_current_cdemo_sk IS NOT NULL
),
RankedSales AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        SUM(cs.ws_sales_price * cs.ws_quantity) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(cs.ws_sales_price * cs.ws_quantity) DESC) AS sales_rank
    FROM
        CustomerSalesCTE cs
    WHERE
        cs.sale_rank <= 5
    GROUP BY
        cs.c_customer_sk, cs.c_first_name, cs.c_last_name
)
SELECT
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    COALESCE(rc.total_refunds, 0) AS total_refunded,
    r.total_sales
FROM
    RankedSales r
LEFT JOIN (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_refunds
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
) rc ON r.c_customer_sk = rc.wr_returning_customer_sk
WHERE
    r.total_sales > 1000
    AND r.c_customer_sk IS NOT NULL
ORDER BY
    r.total_sales DESC
LIMIT 10;
