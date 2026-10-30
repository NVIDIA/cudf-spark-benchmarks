
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
ReturnSummary AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
FinalSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        cs.total_quantity,
        cs.total_sales,
        cs.total_transactions,
        COALESCE(rs.return_count, 0) AS return_count,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        (cs.total_sales - COALESCE(rs.total_return_amount, 0)) AS net_sales
    FROM 
        CustomerSummary AS cs
    LEFT JOIN 
        ReturnSummary AS rs ON cs.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    fs.cd_gender, 
    fs.cd_marital_status, 
    COUNT(fs.c_customer_sk) AS customer_count,
    AVG(fs.total_quantity) AS avg_quantity_per_customer,
    SUM(fs.total_sales) AS total_sales,
    SUM(fs.net_sales) AS total_net_sales,
    SUM(fs.return_count) AS total_returns
FROM 
    FinalSummary AS fs
GROUP BY 
    fs.cd_gender, fs.cd_marital_status
ORDER BY 
    fs.cd_gender, fs.cd_marital_status;
