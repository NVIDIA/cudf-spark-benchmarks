WITH  SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
),
PriceSummary AS (
    SELECT sp.s_suppkey, sp.s_name, SUM(sp.ps_supplycost * sp.ps_availqty) AS total_supply_cost
    FROM SupplierParts sp
    GROUP BY sp.s_suppkey, sp.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
),
FinalReport AS (
    SELECT co.c_name, co.o_orderkey, co.o_orderdate, ps.total_supply_cost
    FROM CustomerOrders co
    JOIN PriceSummary ps ON co.o_orderkey % 100 = ps.s_suppkey % 100 
)
SELECT fr.c_name AS Customer_Name, COUNT(fr.o_orderkey) AS Number_of_Orders, 
       AVG(fr.total_supply_cost) AS Average_Supply_Cost, 
       MIN(fr.o_orderdate) AS First_Order_Date, 
       MAX(fr.o_orderdate) AS Last_Order_Date
FROM FinalReport fr
GROUP BY fr.c_name
ORDER BY Number_of_Orders DESC, Average_Supply_Cost ASC;