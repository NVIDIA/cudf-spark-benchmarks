
WITH RegionData AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
), SupplierData AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           COUNT(l.l_orderkey) AS line_count, o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1995-01-01' 
      AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
), CustomerData AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS spent_amount
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), RankedSuppliers AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY rd.r_name ORDER BY sd.total_supply_cost DESC) AS supplier_rank,
           sd.*, rd.r_name
    FROM SupplierData sd
    JOIN RegionData rd ON sd.s_suppkey % 5 = rd.r_regionkey 
    WHERE sd.total_supply_cost > (
        SELECT AVG(total_supply_cost) FROM SupplierData
    )
)
SELECT cs.c_custkey, cs.spent_amount, 
       rs.r_name, 
       CASE 
           WHEN cs.spent_amount IS NULL THEN 'No Purchases'
           ELSE 'Has Purchases'
       END AS purchase_status,
       COUNT(os.total_order_value) FILTER (WHERE os.line_count > 2) AS high_value_order_count
FROM CustomerData cs
LEFT JOIN OrderSummary os ON cs.c_custkey = os.o_orderkey % 100
JOIN RankedSuppliers rs ON cs.c_custkey % 50 = rs.s_suppkey
GROUP BY cs.c_custkey, cs.spent_amount, rs.r_name, rs.s_suppkey
ORDER BY cs.spent_amount DESC 
LIMIT 10;
