WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_orderdate, 
           o.o_totalprice,
           CAST(o.o_orderkey AS STRING) AS hierarchy
    FROM orders o
    WHERE o.o_orderstatus = 'O'

    UNION ALL

    SELECT oh.o_orderkey, 
           o.o_custkey, 
           o.o_orderdate, 
           o.o_totalprice,
           CAST(oh.hierarchy || ' -> ' || o.o_orderkey AS STRING) AS hierarchy
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderstatus = 'O' 
    AND o.o_orderkey <> oh.o_orderkey
),
SupplierStats AS (
    SELECT s.s_suppkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT p.p_partkey) AS parts_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 50.00
    GROUP BY s.s_suppkey
)
SELECT COALESCE(r.r_name, 'Unknown Region') AS region_name,
       n.n_name AS nation_name,
       COUNT(DISTINCT c.c_custkey) AS customers_count,
       AVG(o.o_totalprice) AS avg_order_value,
       MAX(s.total_supply_cost) AS max_supply_cost,
       COUNT(DISTINCT s.s_suppkey) AS suppliers_count,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN SupplierStats s ON l.l_suppkey = s.s_suppkey
WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY r.r_name, n.n_name
HAVING MAX(o.o_totalprice) > 100.00
ORDER BY customers_count DESC, avg_order_value DESC;