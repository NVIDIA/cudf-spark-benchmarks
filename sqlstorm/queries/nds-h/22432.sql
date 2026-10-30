WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
), 
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM RankedSuppliers s
    WHERE s.rn <= 5
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps
    JOIN TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
), 
CustomerOrders AS (
    SELECT DISTINCT o.o_orderkey, c.c_custkey, c.c_name, o.o_orderdate, o.o_totalprice
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
),
LineItems As (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_price
    FROM lineitem li
    GROUP BY li.l_orderkey
),
FinalResults AS (
    SELECT co.c_custkey, co.c_name, COALESCE(SUM(l.net_price), 0) AS total_spent, 
           COUNT(DISTINCT l.l_orderkey) AS order_count, 
           COUNT(DISTINCT sp.ps_partkey) AS unique_parts_supplied
    FROM CustomerOrders co
    LEFT JOIN LineItems l ON co.o_orderkey = l.l_orderkey
    LEFT JOIN SupplierParts sp ON sp.ps_partkey = l.l_orderkey
    GROUP BY co.c_custkey, co.c_name
)
SELECT fr.*, 
       CASE 
           WHEN fr.total_spent IS NULL THEN 'No Spending'
           WHEN fr.total_spent = 0 THEN 'Zero Spending'
           ELSE 'Active Customer'
       END AS customer_status,
       (SELECT AVG(total_spent) FROM FinalResults) AS avg_spending
FROM FinalResults fr
ORDER BY fr.total_spent DESC NULLS LAST
LIMIT 10;