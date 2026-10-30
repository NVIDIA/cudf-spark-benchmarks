
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        d.d_year,
        d.d_month_seq,
        ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_month_seq ORDER BY ws.ws_net_profit DESC) AS monthly_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
),
TopSales AS (
    SELECT 
        sd.*,
        SUM(sd.ws_net_profit) OVER (PARTITION BY sd.ws_item_sk) AS total_profit_by_item
    FROM SalesData sd
    WHERE sd.monthly_rank <= 5
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
RankedCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.order_count,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM CustomerSales cs
)
SELECT 
    rc.c_customer_sk,
    rc.order_count,
    rc.total_spent,
    ts.ws_item_sk,
    ts.ws_quantity,
    ts.ws_sales_price,
    ts.total_profit_by_item
FROM RankedCustomers rc
JOIN TopSales ts ON rc.order_count > 2
WHERE rc.total_spent > 100
ORDER BY rc.total_spent DESC, ts.total_profit_by_item DESC
