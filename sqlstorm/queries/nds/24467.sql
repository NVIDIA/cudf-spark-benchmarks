
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450120
),
MaxProfitSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        COALESCE(SUM(CASE WHEN cs.cs_item_sk = rs.ws_item_sk THEN cs.cs_ext_discount_amt END), 0) AS total_discount
    FROM 
        RankedSales rs
    LEFT JOIN 
        catalog_sales cs ON cs.cs_item_sk = rs.ws_item_sk AND cs.cs_order_number = rs.ws_order_number
    WHERE 
        rs.rn = 1
    GROUP BY 
        rs.ws_item_sk, rs.ws_order_number, rs.ws_sales_price
),
HighProfitCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ms.ws_sales_price - ms.total_discount) AS net_spent
    FROM 
        customer c
    JOIN 
        MaxProfitSales ms ON ms.ws_order_number IN (
            SELECT ws.ws_order_number 
            FROM web_sales ws 
            WHERE ws.ws_bill_customer_sk = c.c_customer_sk 
              AND ws.ws_sales_price > 100
        )
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ms.ws_sales_price - ms.total_discount) > 1000
),
PromotionalReturns AS (
    SELECT 
        cr.cr_reason_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_return_quantity IS NOT NULL
    GROUP BY 
        cr.cr_reason_sk
)
SELECT 
    hc.c_customer_id,
    hc.c_first_name,
    hc.c_last_name,
    hc.net_spent AS total_spent,
    COALESCE(pr.total_returns, 0) AS total_returns,
    CASE 
        WHEN pr.total_returns > 10 THEN 'High'
        WHEN pr.total_returns > 0 THEN 'Moderate'
        ELSE 'None'
    END AS return_level
FROM 
    HighProfitCustomers hc
LEFT JOIN 
    PromotionalReturns pr ON pr.cr_reason_sk IN (
        SELECT p.p_promo_sk 
        FROM promotion p 
        WHERE p.p_discount_active = 'Y'
    )
ORDER BY 
    total_spent DESC, total_returns ASC
LIMIT 50;
