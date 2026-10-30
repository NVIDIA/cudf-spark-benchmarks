
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk AS CustomerSK,
        SUM(ws_ext_sales_price) AS TotalSales,
        COUNT(ws_order_number) AS OrderCount,
        MIN(d.d_date) AS FirstPurchaseDate,
        MAX(d.d_date) AS LastPurchaseDate,
        cd_gender AS Gender,
        cd_marital_status AS MaritalStatus,
        hd.hd_income_band_sk AS IncomeBand
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        ws_bill_customer_sk, cd_gender, cd_marital_status, hd.hd_income_band_sk
), 
RankedSales AS (
    SELECT 
        CustomerSK,
        TotalSales,
        OrderCount,
        FirstPurchaseDate,
        LastPurchaseDate,
        Gender,
        MaritalStatus,
        IncomeBand,
        RANK() OVER (PARTITION BY Gender, MaritalStatus ORDER BY TotalSales DESC) AS SalesRank
    FROM 
        SalesData
)
SELECT 
    rs.CustomerSK,
    rs.TotalSales,
    rs.OrderCount,
    rs.FirstPurchaseDate,
    rs.LastPurchaseDate,
    rs.Gender,
    rs.MaritalStatus,
    rs.IncomeBand
FROM 
    RankedSales rs
WHERE 
    rs.SalesRank <= 10
ORDER BY 
    rs.Gender, rs.MaritalStatus, rs.TotalSales DESC;
