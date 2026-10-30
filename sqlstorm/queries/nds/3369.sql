
WITH sales_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ws_bill_customer_sk) AS total_customers,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        SUM(ws_ext_tax) AS total_tax,
        AVG(ws_net_paid_inc_tax) AS avg_order_amount,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    JOIN 
        customer_address ON c_current_addr_sk = ca_address_sk
    WHERE 
        ws_sold_date_sk BETWEEN 2458123 AND 2458127
    GROUP BY 
        ca_state
),
popular_items AS (
    SELECT 
        i_item_sk,
        i_item_id,
        SUM(ws_quantity) AS total_sold,
        RANK() OVER (ORDER BY SUM(ws_quantity) DESC) AS item_rank
    FROM 
        web_sales
    JOIN 
        item ON ws_item_sk = i_item_sk
    GROUP BY 
        i_item_sk, i_item_id
)
SELECT 
    ss.ca_state,
    ss.total_customers,
    ss.total_quantity,
    ss.total_sales,
    ss.total_tax,
    ss.avg_order_amount,
    pi.i_item_id,
    pi.total_sold
FROM 
    sales_summary ss
LEFT JOIN 
    popular_items pi ON ss.total_quantity > 100 AND pi.item_rank < 10
WHERE 
    ss.rank <= 5
ORDER BY 
    ss.total_sales DESC, pi.total_sold DESC
LIMIT 20 OFFSET 0;
