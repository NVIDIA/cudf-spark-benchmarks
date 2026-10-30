
WITH SalesData AS (
    SELECT 
        COALESCE(ss.ss_sold_date_sk, cs.cs_sold_date_sk, ws.ws_sold_date_sk) AS Sold_Date_SK,
        COALESCE(ss.ss_item_sk, cs.cs_item_sk, ws.ws_item_sk) AS Item_SK,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS Store_Sales,
        SUM(COALESCE(cs.cs_net_paid, 0)) AS Catalog_Sales,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS Web_Sales
    FROM 
        store_sales ss
    FULL OUTER JOIN catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
    FULL OUTER JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
    GROUP BY 1, 2
),
RankedSales AS (
    SELECT 
        Sold_Date_SK,
        Item_SK,
        Store_Sales,
        Catalog_Sales,
        Web_Sales,
        RANK() OVER (PARTITION BY Sold_Date_SK ORDER BY Store_Sales + Catalog_Sales + Web_Sales DESC) AS Sales_Rank
    FROM SalesData
)

SELECT 
    ds.d_date AS Sales_Date,
    i.i_item_id AS Item_ID,
    r.Sales_Rank,
    COALESCE(r.Store_Sales, 0) AS Store_Sales_Amount,
    COALESCE(r.Catalog_Sales, 0) AS Catalog_Sales_Amount,
    COALESCE(r.Web_Sales, 0) AS Web_Sales_Amount,
    (COALESCE(r.Store_Sales, 0) + COALESCE(r.Catalog_Sales, 0) + COALESCE(r.Web_Sales, 0)) AS Total_Sales
FROM RankedSales r
JOIN date_dim ds ON r.Sold_Date_SK = ds.d_date_sk
JOIN item i ON r.Item_SK = i.i_item_sk
WHERE ds.d_year = 2023 AND r.Sales_Rank <= 10
ORDER BY ds.d_date, Total_Sales DESC;
