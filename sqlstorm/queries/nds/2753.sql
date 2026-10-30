
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
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
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RecentReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        sr_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cs.total_sales,
    cs.order_count,
    COALESCE(rr.return_count, 0) AS return_count,
    COALESCE(rr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        WHEN rr.total_return_amount > 0 THEN 'High Return Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    RankedSales cs
JOIN 
    CustomerDetails cd ON cs.ws_bill_customer_sk = cd.c_customer_sk
LEFT JOIN 
    RecentReturns rr ON cd.c_customer_sk = rr.sr_customer_sk
WHERE 
    cs.sales_rank <= 10
ORDER BY 
    cs.total_sales DESC;
