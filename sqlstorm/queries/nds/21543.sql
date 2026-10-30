
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
), 
demographic_summary AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
account_status AS (
    SELECT 
        cs_bill_customer_sk, 
        COUNT(DISTINCT cs_order_number) AS catalog_order_count, 
        SUM(cs_net_profit) AS catalog_net_profit
    FROM 
        catalog_sales 
    GROUP BY 
        cs_bill_customer_sk
),
return_analysis AS (
    SELECT 
        sr_customer_sk, 
        COUNT(sr_ticket_number) AS return_count, 
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
final_summary AS (
    SELECT 
        ds.ws_bill_customer_sk, 
        ds.total_sales,
        ds.order_count,
        ds.sales_rank,
        dem.cd_gender,
        dem.cd_marital_status,
        dem.cd_purchase_estimate,
        dem.gender_rank,
        COALESCE(sa.catalog_order_count, 0) AS catalog_orders,
        COALESCE(sa.catalog_net_profit, 0.00) AS catalog_net_profit,
        COALESCE(ra.return_count, 0) AS returns,
        COALESCE(ra.total_return_amt, 0.00) AS total_return_amt
    FROM 
        sales_summary ds
    LEFT JOIN 
        demographic_summary dem ON ds.ws_bill_customer_sk = dem.c_customer_sk
    LEFT JOIN 
        account_status sa ON ds.ws_bill_customer_sk = sa.cs_bill_customer_sk
    LEFT JOIN 
        return_analysis ra ON ds.ws_bill_customer_sk = ra.sr_customer_sk
)
SELECT 
    fs.ws_bill_customer_sk, 
    fs.total_sales,
    fs.order_count, 
    fs.sales_rank,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.cd_purchase_estimate,
    fs.gender_rank,
    fs.catalog_orders, 
    fs.catalog_net_profit,
    fs.returns,
    fs.total_return_amt,
    CASE 
        WHEN fs.total_sales > 1000 AND fs.returns = 0 THEN 'High Value Customer'
        WHEN fs.total_sales <= 1000 AND fs.returns > 0 THEN 'Potential Loss'
        ELSE 'Average Customer' 
    END AS customer_status,
    CONCAT('Customer: ', fs.ws_bill_customer_sk, 
           ', Gender: ', fs.cd_gender, 
           ', Marital Status: ', fs.cd_marital_status, 
           ', Sales Total: $', ROUND(fs.total_sales, 2)) AS customer_info
FROM 
    final_summary fs
WHERE 
    fs.total_sales IS NOT NULL 
    AND fs.cd_gender IS NOT NULL
ORDER BY 
    fs.total_sales DESC
LIMIT 100;
