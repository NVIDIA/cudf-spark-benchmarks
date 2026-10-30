WITH  PriceSummary AS (
    SELECT 
        P.p_partkey,
        P.p_name,
        PS.ps_availqty,
        PS.ps_supplycost,
        P.p_retailprice,
        CASE 
            WHEN PS.ps_supplycost IS NULL THEN 'No Supplier'
            ELSE 'Supplier Available' 
        END AS Supplier_Status,
        ROW_NUMBER() OVER (PARTITION BY P.p_partkey ORDER BY PS.ps_supplycost DESC) AS Price_Rank
    FROM part P
    LEFT JOIN partsupp PS ON P.p_partkey = PS.ps_partkey
    WHERE PS.ps_supplycost > 0 OR PS.ps_supplycost IS NULL
),
OrderSummary AS (
    SELECT 
        O.o_orderkey,
        SUM(L.l_quantity) AS Total_Quantity,
        SUM(L.l_extendedprice * (1 - L.l_discount)) AS Total_Revenue,
        AVG(L.l_discount) AS Average_Discount
    FROM orders O
    INNER JOIN lineitem L ON O.o_orderkey = L.l_orderkey
    WHERE 
        O.o_orderstatus = 'F' AND 
        L.l_returnflag = 'N' AND 
        L.l_shipdate > DATE '1997-01-01'
    GROUP BY O.o_orderkey
),
CustomerSummary AS (
    SELECT 
        C.c_custkey,
        C.c_name,
        COUNT(O.o_orderkey) AS Order_Count,
        SUM(O.o_totalprice) AS Total_Spent
    FROM customer C
    LEFT JOIN orders O ON C.c_custkey = O.o_custkey
    GROUP BY C.c_custkey, C.c_name
    HAVING COUNT(O.o_orderkey) > 1
)
SELECT 
    PS.p_partkey,
    PS.p_name,
    COALESCE(OS.Total_Quantity, 0) AS Order_Quantity,
    PS.ps_supplycost AS Supply_Cost,
    CS.Total_Spent AS Customer_Spent,
    PS.Supplier_Status,
    CASE 
        WHEN PS.p_retailprice > 100 THEN 'High Value Part'
        WHEN PS.p_retailprice IS NULL THEN 'Price Unknown'
        ELSE 'Standard Part'
    END AS Part_Value_Category
FROM PriceSummary PS
FULL OUTER JOIN OrderSummary OS ON PS.p_partkey = OS.o_orderkey
FULL OUTER JOIN CustomerSummary CS ON OS.o_orderkey = CS.c_custkey
WHERE 
    (PS.ps_supplycost < (SELECT MIN(p_retailprice) FROM part WHERE p_size < 20) OR PS.ps_supplycost IS NULL) AND
    (CS.Total_Spent IS NULL OR CS.Total_Spent > 1000)
ORDER BY Part_Value_Category, PS.p_name, CS.Total_Spent DESC;