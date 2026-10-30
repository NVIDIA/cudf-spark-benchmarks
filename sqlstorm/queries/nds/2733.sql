
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer_demographics
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM customer AS c
    LEFT JOIN CustomerDemographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns AS cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cd.cd_purchase_estimate > 1000
),
WebSalesWithReturns AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        COALESCE(cr.total_return_quantity, 0) AS return_quantity,
        COALESCE(cr.total_return_amount, 0) AS return_amount
    FROM web_sales AS ws
    LEFT JOIN CustomerReturns AS cr ON ws.ws_bill_customer_sk = cr.sr_customer_sk
),
RankedSales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk) AS cumulative_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS sales_rank
    FROM WebSalesWithReturns AS ws
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    SUM(ws.return_amount) AS total_returned_amount,
    SUM(ws.return_quantity) AS total_returned_quantity,
    AVG(rs.cumulative_profit) AS avg_cumulative_profit
FROM HighValueCustomers AS hvc
JOIN RankedSales AS rs ON hvc.c_customer_sk = rs.ws_order_number
JOIN WebSalesWithReturns AS ws ON rs.ws_order_number = ws.ws_order_number
GROUP BY 
    hvc.c_first_name, 
    hvc.c_last_name, 
    hvc.cd_gender, 
    hvc.cd_marital_status, 
    hvc.c_customer_sk
HAVING 
    AVG(rs.cumulative_profit) > 500
ORDER BY total_returned_amount DESC;
