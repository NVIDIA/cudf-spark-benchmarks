
WITH SalesData AS (
    SELECT
        ss.ss_item_sk AS Item_SK,
        SUM(ss.ss_quantity) AS Total_Quantity,
        SUM(ss.ss_net_paid) AS Total_Sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS Total_Orders
    FROM
        store_sales ss
    JOIN
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY
        ss.ss_item_sk
), RankedSales AS (
    SELECT
        Item_SK,
        Total_Quantity,
        Total_Sales,
        Total_Orders,
        RANK() OVER (ORDER BY Total_Sales DESC) AS Sales_Rank
    FROM
        SalesData
)
SELECT
    i.i_item_id AS Item_ID,
    i.i_item_desc AS Item_Description,
    rs.Total_Quantity,
    rs.Total_Sales,
    rs.Total_Orders,
    rs.Sales_Rank
FROM
    RankedSales rs
JOIN
    item i ON rs.Item_SK = i.i_item_sk
WHERE
    rs.Sales_Rank <= 10
ORDER BY
    rs.Sales_Rank;
