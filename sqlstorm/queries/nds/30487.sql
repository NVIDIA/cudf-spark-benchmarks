
WITH  SalesCTE AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS TotalNetPaid,
        COUNT(DISTINCT ss_ticket_number) AS UniqueTransactions,
        d_year
    FROM 
        store_sales
    JOIN 
        date_dim ON ss_sold_date_sk = d_date_sk
    GROUP BY 
        ss_store_sk, d_year
    HAVING 
        d_year >= 2020
    UNION ALL
    SELECT 
        s.ss_store_sk,
        SUM(s.ss_net_paid + r.wr_net_loss) AS TotalNetPaid,
        COUNT(DISTINCT s.ss_ticket_number) + COUNT(DISTINCT r.wr_order_number) AS UniqueTransactions,
        d.d_year
    FROM 
        store_sales s
    LEFT JOIN 
        web_returns r ON s.ss_item_sk = r.wr_item_sk
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE 
        r.wr_returned_date_sk IS NULL OR d.d_year > 2020
    GROUP BY 
        s.ss_store_sk, d.d_year
),
RankedSales AS (
    SELECT 
        ss_store_sk,
        TotalNetPaid,
        UniqueTransactions,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY TotalNetPaid DESC) AS SalesRank
    FROM 
        SalesCTE
),
FilteredSales AS (
    SELECT 
        f.ss_store_sk, 
        f.TotalNetPaid,
        f.UniqueTransactions,
        COALESCE(d.ca_city, 'Unknown') AS StoreCity,
        CASE 
            WHEN f.UniqueTransactions > 1000 THEN 'High Volume'
            WHEN f.UniqueTransactions BETWEEN 500 AND 1000 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS VolumeCategory
    FROM 
        RankedSales f
    LEFT JOIN 
        store s ON f.ss_store_sk = s.s_store_sk
    LEFT JOIN 
        customer_address d ON s.s_city = d.ca_city
    WHERE 
        f.SalesRank <= 10
)
SELECT 
    StoreCity, 
    COUNT(*) AS StoreCount, 
    AVG(TotalNetPaid) AS AvgNetPaid,
    SUM(UniqueTransactions) AS TotalUniqueTransactions
FROM 
    FilteredSales
GROUP BY 
    StoreCity
HAVING 
    SUM(UniqueTransactions) > 1000
ORDER BY 
    AvgNetPaid DESC
LIMIT 5;
