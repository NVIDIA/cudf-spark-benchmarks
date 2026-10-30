
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_sales_price, 
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
CustomerTotals AS (
    SELECT 
        c_customer_sk,
        SUM(ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss_ticket_number) AS total_purchases
    FROM 
        store_sales s
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c_customer_sk
),
ItemProfit AS (
    SELECT 
        i.i_item_sk, 
        SUM(COALESCE(ws_net_profit, 0)) AS total_profit 
    FROM 
        item i 
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk 
    WHERE 
        i.i_current_price > 100 AND (i.i_item_desc LIKE '%promo%' OR i.i_item_desc IS NOT NULL)
    GROUP BY 
        i.i_item_sk
),
ReturnInfo AS (
    SELECT 
        sr_item_sk, 
        COUNT(sr_ticket_number) AS returns_count, 
        SUM(sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalReport AS (
    SELECT 
        c.c_customer_sk,
        ct.total_spent,
        ct.total_purchases,
        ip.total_profit,
        ri.returns_count,
        ri.total_returned
    FROM 
        CustomerTotals ct 
    JOIN 
        customer c ON ct.c_customer_sk = c.c_customer_sk
    LEFT JOIN 
        ItemProfit ip ON c.c_current_addr_sk = ip.i_item_sk 
    LEFT JOIN 
        ReturnInfo ri ON ip.i_item_sk = ri.sr_item_sk
)
SELECT 
    f.c_customer_sk, 
    f.total_spent, 
    f.total_purchases, 
    f.total_profit,
    f.returns_count,
    COALESCE(f.total_returned, 0) AS net_total_returned,
    CASE 
        WHEN f.total_spent > 1000 THEN 'High Value'
        WHEN f.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    FinalReport f
WHERE 
    f.total_profit IS NOT NULL
ORDER BY 
    f.total_spent DESC;
