
WITH CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'DependentCountNotAvailable'
            WHEN cd.cd_dep_count > 4 THEN 'LargeFamily'
            ELSE 'SmallFamily'
        END AS FamilyType
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        d.d_year,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year > 2020
    GROUP BY ws.ws_item_sk, d.d_year
),
ReturnData AS (
    SELECT 
        COUNT(DISTINCT wr.wr_order_number) AS total_returns,
        wr.wr_item_sk,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(wr.wr_return_quantity) AS total_returned_quantity
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
FinalReport AS (
    SELECT 
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        sd.total_quantity,
        sd.total_net_paid,
        rd.total_returns,
        rd.total_returned_quantity,
        nd.d_year
    FROM CustomerDetails cd
    INNER JOIN SalesData sd ON sd.ws_item_sk = (
        SELECT ws_item_sk
        FROM SalesData sd2
        WHERE sd2.rank_sales = 1
    )
    LEFT JOIN ReturnData rd ON rd.wr_item_sk = sd.ws_item_sk
    INNER JOIN date_dim nd ON nd.d_date_sk = sd.d_year
    WHERE cd.FamilyType = 'LargeFamily'
    AND (sd.total_net_paid IS NOT NULL OR rd.total_returns IS NOT NULL)
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    COALESCE(fr.total_quantity, 0) AS total_quantity,
    COALESCE(fr.total_net_paid, 0) AS total_net_paid,
    COALESCE(fr.total_returns, 0) AS total_returns,
    CASE 
        WHEN fr.total_returned_quantity > 0 THEN 'HasReturnedItems'
        ELSE 'NoReturns'
    END AS return_status,
    fr.d_year
FROM FinalReport fr
ORDER BY fr.total_net_paid DESC, fr.c_last_name ASC;
