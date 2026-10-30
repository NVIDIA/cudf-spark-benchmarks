WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) as rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           AVG(ps.ps_supplycost) as avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
    HAVING AVG(ps.ps_supplycost) < 200.00
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, n.n_name as nation, 
           SUM(ps.ps_availqty) as total_avail_qty
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT s.*, 
           RANK() OVER (ORDER BY s.total_avail_qty DESC) as supplier_rank
    FROM SupplierInfo s
),
FinalResults AS (
    SELECT ro.o_orderkey, ro.o_orderdate, 
           SUM(li.l_extendedprice * (1 - li.l_discount)) as total_revenue,
           p.p_name, p.avg_supplycost
    FROM RankedOrders ro
    JOIN lineitem li ON ro.o_orderkey = li.l_orderkey
    JOIN HighValueParts p ON li.l_partkey = p.p_partkey
    LEFT JOIN TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
    WHERE ro.rn <= 5 AND ts.supplier_rank IS NOT NULL
    GROUP BY ro.o_orderkey, ro.o_orderdate, p.p_name, p.avg_supplycost
)
SELECT f.o_orderkey, f.o_orderdate, f.total_revenue, 
       CASE WHEN f.avg_supplycost IS NULL THEN 'No Cost' 
            ELSE CONCAT('Avg Cost: ', CAST(f.avg_supplycost AS STRING)) 
       END as cost_information
FROM FinalResults f
ORDER BY f.total_revenue DESC
LIMIT 10;
