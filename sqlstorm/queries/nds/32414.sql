
WITH  SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_net_paid,
        ws_sold_date_sk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk,
        ws_sold_date_sk
    HAVING 
        SUM(ws_quantity) > 0
),
RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_quantity DESC) AS rank
    FROM 
        SalesData sd
),
CustomerLifetime AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS lifetime_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cl.c_customer_sk,
        cl.lifetime_value,
        ROW_NUMBER() OVER (ORDER BY cl.lifetime_value DESC) AS customer_rank
    FROM 
        CustomerLifetime cl
    WHERE 
        cl.lifetime_value > 1000
),
FinalReport AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.lifetime_value,
        COUNT(DISTINCT rs.ws_item_sk) AS unique_items_purchased,
        SUM(rs.total_quantity) AS total_items_purchased
    FROM 
        HighValueCustomers hvc
    JOIN 
        RankedSales rs ON hvc.c_customer_sk = rs.ws_item_sk
    GROUP BY 
        hvc.c_customer_sk, hvc.lifetime_value
)
SELECT 
    fr.c_customer_sk,
    fr.lifetime_value,
    COALESCE(fr.unique_items_purchased, 0) AS unique_items,
    COALESCE(fr.total_items_purchased, 0) AS total_items,
    CASE 
        WHEN fr.lifetime_value > 5000 THEN 'VIP'
        WHEN fr.lifetime_value BETWEEN 2000 AND 5000 THEN 'Regular'
        ELSE 'Occasional'
    END AS customer_segment
FROM 
    FinalReport fr
LEFT JOIN 
    customer_address ca ON fr.c_customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_country IS NULL OR ca.ca_country = 'USA'
ORDER BY 
    fr.lifetime_value DESC, fr.total_items_purchased DESC;
