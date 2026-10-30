
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS TotalPurchaseCount,
        SUM(ws.ws_sales_price) AS TotalSpent,
        AVG(ws.ws_sales_price) AS AverageSpent,
        COUNT(DISTINCT sr.sr_ticket_number) AS TotalReturns
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE 
        c.c_current_addr_sk IN (
            SELECT ca_address_sk 
            FROM customer_address 
            WHERE ca_state = 'CA'
        )
    GROUP BY 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
), 
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.TotalPurchaseCount,
        cs.TotalSpent,
        cs.AverageSpent,
        cs.TotalReturns,
        CASE 
            WHEN cs.TotalSpent > 1000 THEN 'High Value'
            WHEN cs.TotalSpent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS ValueSegment
    FROM 
        CustomerStats cs
)
SELECT 
    hv.ValueSegment,
    COUNT(hv.c_customer_sk) AS CustomerCount,
    AVG(hv.TotalSpent) AS AverageSpentBySegment,
    SUM(hv.TotalReturns) AS TotalReturnsBySegment
FROM 
    HighValueCustomers hv
GROUP BY 
    hv.ValueSegment
ORDER BY 
    CASE hv.ValueSegment
        WHEN 'High Value' THEN 1
        WHEN 'Medium Value' THEN 2
        WHEN 'Low Value' THEN 3
        ELSE 4
    END;
