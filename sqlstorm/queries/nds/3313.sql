
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_sales_amount,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY 
        ws_bill_customer_sk
), CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
)
SELECT 
    d.customer_sk AS c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    d.total_sales_amount,
    COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
    d.total_orders,
    d.avg_sales_price,
    CASE 
        WHEN d.total_sales_amount > 1000 THEN 'High Value'
        WHEN d.total_sales_amount BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment,
    CASE 
        WHEN r.total_returns > 5 THEN 'High Return Customer'
        ELSE 'Regular Customer'
    END AS return_status
FROM 
    SalesData d
LEFT JOIN 
    CustomerReturns r ON d.customer_sk = r.sr_customer_sk
JOIN 
    CustomerDemographics cd ON cd.c_customer_sk = d.customer_sk
WHERE 
    cd.hd_income_band_sk IS NOT NULL 
    AND cd.cd_marital_status = 'M'
ORDER BY 
    d.total_sales_amount DESC;
