
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
), 
SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), 
HighCostSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sc.total_supply_cost,
        sc.part_count
    FROM SupplierCosts sc
    JOIN supplier s ON sc.s_suppkey = s.s_suppkey
    WHERE sc.total_supply_cost > (
        SELECT AVG(total_supply_cost) FROM SupplierCosts
    )
), 
FinalOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY o.o_orderdate DESC) AS nation_order_rank
    FROM RankedOrders o
    JOIN customer c ON o.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_orderkey = o.o_orderkey 
        AND l.l_returnflag = 'R'
    )
)
SELECT 
    fo.o_orderkey,
    fo.o_totalprice,
    hcs.s_name,
    fo.nation_name
FROM FinalOrders fo
FULL OUTER JOIN HighCostSuppliers hcs ON fo.o_orderkey IS NOT NULL AND hcs.s_suppkey IS NULL
WHERE fo.nation_order_rank <= 5 OR hcs.part_count > 10
ORDER BY fo.o_totalprice DESC NULLS LAST;
