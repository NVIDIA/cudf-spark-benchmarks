
WITH CustomerRanked AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
), ReturnSummary AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), CustomerPerformance AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(ss.total_sales, 0) = 0 THEN 0
            ELSE (COALESCE(rs.total_return_amount, 0) / COALESCE(ss.total_sales, 0)) * 100 
        END AS return_percentage
    FROM 
        CustomerRanked cr
    LEFT JOIN 
        SalesSummary ss ON cr.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN 
        ReturnSummary rs ON cr.c_customer_sk = rs.sr_customer_sk
    WHERE 
        cr.rn <= 10
)
SELECT 
    cp.c_first_name, 
    cp.c_last_name, 
    cp.total_sales, 
    cp.total_return_amount, 
    cp.return_percentage
FROM 
    CustomerPerformance cp
WHERE 
    cp.return_percentage > 10
ORDER BY 
    cp.return_percentage DESC;
