
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS TotalOrders,
        SUM(ws_ext_sales_price) AS TotalSales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS SalesRank
    FROM 
        web_sales
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_gender = 'M' 
        AND cd_marital_status = 'M'
        AND cd_purchase_estimate > 1000
    GROUP BY 
        ws_bill_customer_sk
),
TopSales AS (
    SELECT 
        ws_bill_customer_sk,
        TotalOrders,
        TotalSales
    FROM 
        RankedSales
    WHERE 
        SalesRank <= 10
)
SELECT 
    ca_city,
    ca_state,
    COUNT(*) AS CustomerCount,
    SUM(TotalSales) AS TotalSalesValue
FROM 
    TopSales
JOIN 
    customer ON TopSales.ws_bill_customer_sk = c_customer_sk
JOIN 
    customer_address ON c_current_addr_sk = ca_address_sk
GROUP BY 
    ca_city, ca_state
ORDER BY 
    TotalSalesValue DESC;
