
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS GenderRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
TopCustomers AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name, 
        rc.c_last_name, 
        rc.cd_gender, 
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.GenderRank <= 5
), 
SalesSummary AS (
    SELECT 
        ws.ws_ship_date_sk, 
        SUM(ws.ws_quantity) AS TotalQuantity, 
        SUM(ws.ws_net_profit) AS TotalProfit
    FROM 
        web_sales ws
    JOIN 
        TopCustomers tc ON ws.ws_bill_customer_sk = tc.c_customer_sk
    GROUP BY 
        ws.ws_ship_date_sk
)
SELECT 
    dd.d_date,
    SUM(ss.TotalQuantity) AS DailyTotalQuantity,
    SUM(ss.TotalProfit) AS DailyTotalProfit
FROM 
    SalesSummary ss
JOIN 
    date_dim dd ON ss.ws_ship_date_sk = dd.d_date_sk
GROUP BY 
    dd.d_date
ORDER BY 
    dd.d_date DESC
LIMIT 30;
