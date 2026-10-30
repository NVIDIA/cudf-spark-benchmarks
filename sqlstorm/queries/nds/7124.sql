
WITH CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), SalesData AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY
        ws.ws_bill_customer_sk
), Summary AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        ci.ca_city,
        ci.ca_state,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_tax, 0) AS total_tax,
        COALESCE(sd.total_discount, 0) AS total_discount
    FROM
        CustomerInfo ci
    LEFT JOIN
        SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
), RankSummary AS (
    SELECT
        s.*,
        RANK() OVER (PARTITION BY s.ca_state ORDER BY s.total_sales DESC) AS sales_rank
    FROM
        Summary s
)
SELECT
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_education_status,
    r.cd_purchase_estimate,
    r.cd_credit_rating,
    r.ca_city,
    r.ca_state,
    r.total_sales,
    r.total_tax,
    r.total_discount,
    r.sales_rank
FROM
    RankSummary r
WHERE
    r.sales_rank <= 10
ORDER BY
    r.ca_state, r.sales_rank;
