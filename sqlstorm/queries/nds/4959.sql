
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_net_loss) AS total_net_loss
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
DemographicData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_state
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
RankedCustomers AS (
    SELECT 
        dd.c_customer_sk,
        dd.cd_gender,
        dd.cd_marital_status,
        dd.cd_purchase_estimate,
        dd.ca_state,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_net_loss, 0) AS total_net_loss,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY dd.ca_state ORDER BY COALESCE(sd.total_sales, 0) DESC) AS sales_rank
    FROM 
        DemographicData dd
    LEFT JOIN 
        CustomerReturns cr ON dd.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesData sd ON dd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    r.cd_gender,
    r.cd_marital_status,
    COUNT(*) AS num_customers,
    AVG(r.total_sales) AS avg_sales,
    AVG(r.total_returns) AS avg_returns,
    AVG(r.total_net_loss) AS avg_net_loss
FROM 
    RankedCustomers r
WHERE 
    r.sales_rank <= 10 AND r.total_sales > 1000
GROUP BY 
    r.cd_gender, r.cd_marital_status
ORDER BY 
    r.cd_gender, r.cd_marital_status;
