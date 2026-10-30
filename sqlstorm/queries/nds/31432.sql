
WITH  SalesCTE AS (
    SELECT 
        ws_order_number, 
        ws_item_sk, 
        ws_quantity, 
        ws_net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
),
FilteredSales AS (
    SELECT 
        s.ss_ticket_number, 
        s.ss_item_sk, 
        s.ss_quantity, 
        s.ss_net_paid, 
        s.ss_ext_sales_price,
        CASE 
            WHEN s.ss_net_paid - s.ss_ext_discount_amt < 0 THEN 0
            ELSE s.ss_net_paid - s.ss_ext_discount_amt 
        END AS adjusted_net_paid
    FROM 
        store_sales s
    JOIN 
        SalesCTE w ON s.ss_item_sk = w.ws_item_sk
    WHERE 
        w.rn <= 5
)
SELECT 
    f.ss_ticket_number,
    f.ss_item_sk,
    SUM(f.ss_quantity) AS total_quantity,
    AVG(f.adjusted_net_paid) AS avg_adjusted_net_paid,
    MAX(f.ss_ext_sales_price) AS max_sales_price,
    MIN(f.ss_ext_sales_price) AS min_sales_price
FROM 
    FilteredSales f
GROUP BY 
    f.ss_ticket_number,
    f.ss_item_sk
HAVING 
    SUM(f.ss_quantity) > 10
ORDER BY 
    total_quantity DESC;
