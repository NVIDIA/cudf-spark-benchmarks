
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_net_paid) AS total_net_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(ss.total_sold_quantity, 0) AS total_sold_quantity,
    COALESCE(ss.total_net_sales, 0) AS total_net_sales,
    (CASE 
        WHEN COALESCE(cr.total_returns, 0) > 0 THEN 'High Return'
        ELSE 'Low Return'
    END) AS return_category,
    DENSE_RANK() OVER (ORDER BY COALESCE(ss.total_net_sales, 0) DESC) AS sales_rank
FROM 
    CustomerDetails cd
LEFT JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    cd.cd_purchase_estimate > 500
ORDER BY 
    sales_rank
LIMIT 100;
