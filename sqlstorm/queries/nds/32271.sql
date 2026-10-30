
WITH  SalesRank AS (
    SELECT 
        ws_bill_customer_sk AS CustomerID,
        SUM(ws_ext_sales_price) AS TotalSales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS Rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        CustomerID,
        TotalSales
    FROM 
        SalesRank
    WHERE 
        Rank <= 10
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        coalesce(hd.hd_buy_potential, 'Unknown') AS BuyPotential
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
SaleswithDetails AS (
    SELECT 
        tc.CustomerID,
        cu.c_first_name,
        cu.c_last_name,
        cu.ca_city,
        cu.ca_state,
        tc.TotalSales,
        CASE 
            WHEN tc.TotalSales > 1000 THEN 'High Value'
            WHEN tc.TotalSales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS CustomerValue
    FROM 
        TopCustomers tc
        JOIN CustomerDetails cu ON tc.CustomerID = cu.c_customer_sk
)
SELECT 
    sd.CustomerValue,
    COUNT(*) AS CountCustomers,
    SUM(sd.TotalSales) AS TotalSalesValue,
    AVG(sd.TotalSales) AS AvgSalesValue
FROM 
    SaleswithDetails sd
GROUP BY 
    sd.CustomerValue
ORDER BY 
    TotalSalesValue DESC;
