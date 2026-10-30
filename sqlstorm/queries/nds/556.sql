
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
HighReturningCustomers AS (
    SELECT
        cr.sr_customer_sk,
        cr.return_count,
        cr.total_return_amt,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM
        CustomerReturns cr
    JOIN
        customer_demographics cd ON cr.sr_customer_sk = cd.cd_demo_sk
    WHERE
        cr.return_count > 5
),
SalesData AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
),
CustomerSalesAnalysis AS (
    SELECT
        hrc.sr_customer_sk,
        hrc.return_count,
        hrc.total_return_amt,
        sd.total_sales,
        sd.order_count,
        ROW_NUMBER() OVER (PARTITION BY hrc.sr_customer_sk ORDER BY hrc.total_return_amt DESC) AS rank
    FROM
        HighReturningCustomers hrc
    LEFT JOIN
        SalesData sd ON hrc.sr_customer_sk = sd.ws_bill_customer_sk
),
FinalResults AS (
    SELECT
        csa.sr_customer_sk,
        csa.total_sales,
        csa.return_count,
        COALESCE(csa.total_return_amt, 0) AS total_return_amt,
        COALESCE(csa.order_count, 0) AS order_count,
        CASE 
            WHEN csa.order_count > 20 THEN 'High Activity'
            WHEN csa.order_count BETWEEN 10 AND 20 THEN 'Medium Activity'
            ELSE 'Low Activity'
        END AS activity_level
    FROM
        CustomerSalesAnalysis csa
)

SELECT
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    fr.sr_customer_sk,
    fr.total_sales,
    fr.total_return_amt,
    fr.activity_level
FROM
    FinalResults fr
JOIN
    customer_address ca ON ca.ca_address_sk = fr.sr_customer_sk
WHERE
    fr.total_sales IS NOT NULL
ORDER BY
    fr.total_sales DESC, fr.total_return_amt DESC;
