
WITH RankedSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_profit) AS total_profit, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
    GROUP BY 
        c.c_customer_id
), HighValueCustomers AS (
    SELECT 
        r.c_customer_id,
        r.total_profit,
        r.order_count,
        RANK() OVER (ORDER BY r.total_profit DESC) AS customer_rank
    FROM 
        RankedSales r
    WHERE 
        r.profit_rank = 1 OR (r.order_count > 5 AND r.total_profit IS NOT NULL)
), CustomerAddresses AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        COALESCE(ca.ca_zip, 'UNKNOWN') AS zip_code
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), FinalReport AS (
    SELECT 
        hvc.c_customer_id,
        hvc.total_profit,
        hvc.order_count,
        ca.ca_city,
        ca.ca_state,
        ca.zip_code,
        CASE 
            WHEN hvc.customer_rank <= 10 THEN 'Top Tier'
            WHEN hvc.customer_rank BETWEEN 11 AND 50 THEN 'Mid Tier'
            ELSE 'Low Tier'
        END AS customer_tier
    FROM 
        HighValueCustomers hvc
    JOIN 
        CustomerAddresses ca ON hvc.c_customer_id = ca.c_customer_id
)
SELECT 
    f.*,
    CASE 
        WHEN f.total_profit IS NULL THEN 'No Profit Recorded'
        ELSE CONCAT('Profit: $', ROUND(f.total_profit, 2))
    END AS profit_statement
FROM 
    FinalReport f
WHERE 
    f.ca_city IS NOT NULL 
    AND (f.ca_state IN ('NY', 'CA') OR f.zip_code = 'UNKNOWN')
ORDER BY 
    f.total_profit DESC, f.c_customer_id
LIMIT 100;
