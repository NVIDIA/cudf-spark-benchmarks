
WITH SalesSummary AS (
    SELECT
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN ws.ws_sales_price ELSE 0 END) AS preferred_sales
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        d.d_year
),
DiscountAnalysis AS (
    SELECT
        s.s_store_sk,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS discount_count
    FROM
        store_sales ss
    JOIN
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE
        ss.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 365
    GROUP BY
        s.s_store_sk
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        SUM(ws.ws_sales_price) AS gender_sales,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer_demographics cd
    JOIN
        web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY
        cd.cd_gender
),
ComplexReturns AS (
    SELECT
        COALESCE(sr.sr_item_sk, cr.cr_item_sk) AS item_sk,
        SUM(COALESCE(sr.sr_return_amt, 0) + COALESCE(cr.cr_return_amount, 0)) AS total_returned
    FROM
        store_returns sr
    FULL OUTER JOIN
        catalog_returns cr ON sr.sr_item_sk = cr.cr_item_sk
    GROUP BY
        COALESCE(sr.sr_item_sk, cr.cr_item_sk)
)
SELECT
    ss.d_year,
    ss.total_sales,
    ss.order_count,
    ss.avg_net_profit,
    ss.preferred_sales,
    da.total_discount,
    da.discount_count,
    cd.cd_gender,
    cd.gender_sales,
    cd.avg_purchase_estimate,
    cr.item_sk,
    cr.total_returned
FROM
    SalesSummary ss
JOIN
    DiscountAnalysis da ON da.total_discount > 1000
LEFT JOIN
    CustomerDemographics cd ON cd.gender_sales > 5000
LEFT JOIN
    ComplexReturns cr ON cr.total_returned > 50
ORDER BY
    ss.d_year DESC, ss.total_sales DESC;
