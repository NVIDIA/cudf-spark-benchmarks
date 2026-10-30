
WITH RankedSales AS (
    SELECT 
        ss_item_sk,
        ss_store_sk,
        ss_net_paid_inc_tax,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY ss_net_paid_inc_tax DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
),
CustomerRefunds AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_amt_inc_tax) AS total_refunds,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS demographic_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)

SELECT 
    s.ss_item_sk,
    s.ss_store_sk,
    s.ss_net_paid_inc_tax,
    COALESCE(r.total_refunds, 0) AS refund_amount,
    SUM(COALESCE(r.total_refunds, 0)) OVER (PARTITION BY s.ss_store_sk ORDER BY s.ss_item_sk) AS cumulative_refunds,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    RankedSales s
LEFT JOIN 
    CustomerRefunds r ON s.ss_item_sk = r.sr_item_sk
JOIN 
    CustomerDemographics cd ON cd.c_customer_sk = s.ss_store_sk
WHERE 
    s.sales_rank <= 10 AND
    (cd.cd_gender = 'M' OR cd.cd_marital_status = 'S')
ORDER BY 
    s.ss_store_sk, s.ss_item_sk;
