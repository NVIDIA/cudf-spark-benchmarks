
WITH  SalesCTE AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        store s
    LEFT JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
    GROUP BY 
        s.s_store_sk, s.s_store_name

    UNION ALL

    SELECT 
        sc.s_store_sk,
        sc.s_store_name,
        SUM(cs.cs_sales_price) AS total_sales
    FROM 
        store sc
    LEFT JOIN 
        catalog_sales cs ON sc.s_store_sk = cs.cs_call_center_sk
    WHERE 
        cs.cs_sold_date_sk IS NOT NULL
    GROUP BY 
        sc.s_store_sk, sc.s_store_name
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_item_sk) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
RankedSales AS (
    SELECT 
        s.s_store_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesCTE s
)
SELECT 
    r.sales_rank,
    r.s_store_name,
    COALESCE(rr.total_returns, 0) AS total_returns,
    COALESCE(rr.total_return_amt, 0) AS total_return_amt
FROM 
    RankedSales r
LEFT JOIN 
    CustomerReturns rr ON r.sales_rank = rr.sr_customer_sk
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_rank;
