
WITH  sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_paid) > 100.00
), sales_by_hour AS (
    SELECT 
        t.t_hour,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales AS ws
    JOIN 
        time_dim AS t ON ws.ws_sold_time_sk = t.t_time_sk
    GROUP BY 
        t.t_hour
), avg_sales AS (
    SELECT 
        AVG(total_quantity) AS average_quantity
    FROM 
        sales_by_hour
), high_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS high_sales_rank
    FROM 
        sales_data AS sd
    JOIN 
        item AS i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL 
        AND i.i_current_price > 20.00
), failing_customers AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
    HAVING 
        COUNT(DISTINCT sr_ticket_number) > (
            SELECT 
                COALESCE(AVG(return_count), 0)
            FROM 
                (SELECT 
                    sr_customer_sk, 
                    COUNT(DISTINCT sr_ticket_number) AS return_count
                FROM 
                    store_returns
                GROUP BY 
                    sr_customer_sk) AS subquery
        )
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    hs.total_sales AS total_sales,
    sb.total_quantity AS total_quantity,
    CASE 
        WHEN fc.return_count IS NULL THEN 'No Returns'
        ELSE 'Frequent Returns'
    END AS customer_return_status
FROM 
    high_sales AS hs
JOIN 
    item AS i ON hs.ws_item_sk = i.i_item_sk
LEFT JOIN 
    failing_customers AS fc ON i.i_item_sk = fc.sr_customer_sk
JOIN 
    sales_by_hour AS sb ON sb.t_hour BETWEEN 9 AND 17
WHERE 
    hs.high_sales_rank <= 10
ORDER BY 
    total_sales DESC, 
    total_quantity DESC;
