
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    JOIN 
        customer c ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
DemographicStats AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
Summary AS (
    SELECT 
        d.cd_demo_sk,
        d.cd_gender,
        d.cd_marital_status,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(sd.total_sales_amount, 0) AS total_sales_amount,
        d.avg_purchase_estimate,
        d.customer_count
    FROM 
        DemographicStats d
    LEFT JOIN 
        CustomerReturns cr ON d.cd_demo_sk = cr.c_customer_sk
    LEFT JOIN 
        SalesData sd ON d.cd_demo_sk = sd.customer_id
)

SELECT 
    cd_gender,
    cd_marital_status,
    SUM(total_returned_quantity) AS total_returned_quantity,
    SUM(total_returned_amount) AS total_returned_amount,
    SUM(total_quantity_sold) AS total_quantity_sold,
    SUM(total_sales_amount) AS total_sales_amount,
    AVG(avg_purchase_estimate) AS avg_purchase_estimate,
    SUM(customer_count) AS total_customers
FROM 
    Summary
GROUP BY 
    cd_gender, cd_marital_status
ORDER BY 
    cd_gender, cd_marital_status;
