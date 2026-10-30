
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        d.d_year,
        d.d_month_seq
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim) 
      AND cd.cd_gender IN ('F', 'M')
), 
ReturnsCTE AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rr.total_returns, 0) AS total_returns,
    (COALESCE(rs.total_sales, 0) - COALESCE(rr.total_returns, 0)) AS net_sales,
    CASE
        WHEN COALESCE(rs.total_sales, 0) > 0 THEN (COALESCE(rs.total_sales, 0) - COALESCE(rr.total_returns, 0)) * 100.0 / COALESCE(rs.total_sales, 0)
        ELSE 0
    END AS return_ratio,
    COUNT(DISTINCT cd.c_customer_sk) AS unique_customers
FROM item i
LEFT JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.sales_rank = 1
LEFT JOIN ReturnsCTE rr ON i.i_item_sk = rr.sr_item_sk
INNER JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
WHERE 
    i.i_current_price > (SELECT AVG(i_current_price) FROM item) 
    AND (i.i_size IS NOT NULL OR i.i_color IS NOT NULL)
GROUP BY 
    i.i_item_id, 
    i.i_item_desc, 
    COALESCE(rs.total_sales, 0), 
    COALESCE(rr.total_returns, 0)
HAVING 
    (COALESCE(rs.total_sales, 0) - COALESCE(rr.total_returns, 0)) > 0
ORDER BY net_sales DESC
LIMIT 10;
