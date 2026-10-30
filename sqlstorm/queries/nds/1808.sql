
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk > 0
),
CustomerIncome AS (
    SELECT 
        cd.cd_demo_sk,
        ib.ib_income_band_sk,
        COALESCE(SUM(ws.ws_quantity), 0) AS TotalQuantity,
        COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS TotalSales
    FROM 
        customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, ib.ib_income_band_sk
),
HighValueSales AS (
    SELECT 
        cus.cd_demo_sk,
        cus.ib_income_band_sk,
        cus.TotalQuantity,
        cus.TotalSales
    FROM 
        CustomerIncome cus
    WHERE 
        cus.TotalSales > (SELECT AVG(TotalSales) FROM CustomerIncome)
)

SELECT 
    con.c_customer_id,
    ca.ca_city,
    SUM(hvs.TotalSales) AS HighValueSalesTotal,
    CASE 
        WHEN SUM(hvs.TotalSales) IS NULL OR SUM(hvs.TotalSales) = 0 THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS SalesStatus,
    COUNT(DISTINCT hvs.ib_income_band_sk) AS UniqueIncomeBands
FROM 
    customer con
LEFT JOIN 
    customer_address ca ON con.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    HighValueSales hvs ON con.c_current_cdemo_sk = hvs.cd_demo_sk
GROUP BY 
    con.c_customer_id, ca.ca_city
HAVING 
    SUM(hvs.TotalSales) >= 1000
ORDER BY 
    HighValueSalesTotal DESC;
