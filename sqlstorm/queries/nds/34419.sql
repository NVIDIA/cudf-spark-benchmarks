
WITH  TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
CombinedSales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        COALESCE(ss.total_spent, 0) AS customer_spending
    FROM 
        SalesData sd
    LEFT JOIN 
        (SELECT c.c_customer_sk, tc.total_spent
         FROM TopCustomers tc
         JOIN customer c ON tc.c_customer_sk = c.c_customer_sk) ss
    ON sd.ws_item_sk = ss.c_customer_sk
),
RankedSales AS (
    SELECT 
        cs.ws_sold_date_sk,
        cs.ws_item_sk,
        cs.total_quantity,
        cs.customer_spending,
        ROW_NUMBER() OVER(PARTITION BY cs.ws_item_sk ORDER BY cs.customer_spending DESC) AS rank
    FROM 
        CombinedSales cs
)
SELECT 
    d.d_date,
    i.i_product_name,
    r.rank,
    r.total_quantity,
    r.customer_spending,
    CASE 
        WHEN r.customer_spending IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM 
    RankedSales r
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
JOIN 
    date_dim d ON r.ws_sold_date_sk = d.d_date_sk
WHERE 
    r.rank = 1
ORDER BY 
    d.d_date DESC, 
    r.customer_spending DESC;
