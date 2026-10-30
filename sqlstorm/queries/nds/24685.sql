
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        RANK() OVER (PARTITION BY sr_returned_date_sk ORDER BY SUM(sr_return_amt) DESC) AS rnk
    FROM
        store_returns
    GROUP BY
        sr_returned_date_sk
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        COALESCE(cd_credit_rating, 'Unknown') AS normalized_credit_rating
    FROM
        customer_demographics
    WHERE
        cd_purchase_estimate > 50000
),
TopStores AS (
    SELECT
        s_store_sk,
        s_store_name,
        SUM(ss_net_paid) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM
        store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY
        s_store_sk, s_store_name
)
SELECT
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.normalized_credit_rating,
    rr.total_returns,
    rr.total_return_amt,
    ts.sales_rank
FROM
    customer_address ca
LEFT JOIN
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN
    RankedReturns rr ON rr.sr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = DATE '2002-10-01')
LEFT JOIN
    TopStores ts ON ts.s_store_sk = (SELECT s_store_sk FROM store ORDER BY s_store_sk LIMIT 1)
WHERE
    (ca.ca_state IN ('CA', 'TX')
    OR ca.ca_city IS NULL
    OR cd.cd_gender = 'F')
AND COALESCE(cd.cd_marital_status, 'U') <> 'S'
ORDER BY
    rr.total_return_amt DESC,
    ts.total_sales DESC
LIMIT 10;
