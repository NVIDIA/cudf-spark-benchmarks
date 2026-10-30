
WITH TotalSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS TotalSalesAmount,
        COUNT(ws_order_number) AS OrderCount,
        AVG(ws_net_profit) AS AvgProfit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ts.TotalSalesAmount,
        ts.OrderCount,
        ts.AvgProfit
    FROM 
        TotalSales ts
    JOIN 
        customer c ON ts.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ts.TotalSalesAmount > 1000
    ORDER BY 
        ts.TotalSalesAmount DESC
    LIMIT 10
),
CustomerDemographics AS (
    SELECT 
        cu.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        TopCustomers tc
    JOIN 
        customer cu ON tc.c_customer_id = cu.c_customer_id
    LEFT JOIN 
        customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cdem.c_customer_id,
    cdem.cd_gender,
    cdem.cd_marital_status,
    cdem.cd_education_status,
    tc.TotalSalesAmount,
    tc.OrderCount,
    tc.AvgProfit
FROM 
    CustomerDemographics cdem
JOIN 
    TopCustomers tc ON cdem.c_customer_id = tc.c_customer_id
ORDER BY 
    tc.TotalSalesAmount DESC;
