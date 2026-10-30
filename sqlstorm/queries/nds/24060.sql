
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_ext_sales_price DESC) AS rn,
        SUM(cs.cs_quantity) OVER (PARTITION BY cs.cs_item_sk) AS total_quantity,
        SUM(cs.cs_ext_sales_price) OVER (PARTITION BY cs.cs_item_sk) AS total_sales_value
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk >= (
            SELECT MAX(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 12
        )
),
AggregatedReturns AS (
    SELECT 
        coalesce(sum(sr_return_quantity), 0) AS total_returned_quantity,
        sr_item_sk
    FROM store_returns sr
    GROUP BY sr_item_sk
),
FinalReport AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(CASE WHEN ws.ws_sales_price - ws.ws_ext_discount_amt > 100 THEN 'High Value' ELSE 'Regular' END) AS order_value_category,
        COALESCE(rs.total_quantity, 0) AS total_sales_quantity,
        COALESCE(ar.total_returned_quantity, 0) AS total_returned_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        RankedSales rs ON ss.ss_item_sk = rs.cs_item_sk AND ss.ss_ticket_number = rs.cs_order_number
    LEFT JOIN 
        AggregatedReturns ar ON ss.ss_item_sk = ar.sr_item_sk
    WHERE 
        ca.ca_state = 'NY' AND 
        ws.ws_sold_date_sk IS NOT NULL AND 
        c.c_first_name IS NOT NULL
    GROUP BY 
        c.c_customer_id, ca.ca_city, rs.total_quantity, ar.total_returned_quantity
    HAVING 
        SUM(ws.ws_net_profit) > 0 AND
        SUM(ws.ws_net_profit) < (
            SELECT AVG(ws1.ws_net_profit) * 1.5 
            FROM web_sales ws1 
            WHERE ws1.ws_ship_date_sk IS NOT NULL
        )
)
SELECT 
    *,
    CASE 
        WHEN total_returned_quantity > total_sales_quantity * 0.1 THEN 'High Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_rate_category
FROM 
    FinalReport
ORDER BY 
    total_net_profit DESC, total_orders ASC;
