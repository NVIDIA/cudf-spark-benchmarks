WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_regionkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM orders o
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
      AND o.o_totalprice > 500
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(r.total_supply_cost, 0) AS total_supply_cost,
    COUNT(DISTINCT fo.o_orderkey) AS order_count,
    AVG(fo.o_totalprice) AS avg_order_price,
    SUM(l.l_quantity) AS total_quantity_sold
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN FilteredOrders fo ON l.l_orderkey = fo.o_orderkey
LEFT JOIN RankedSuppliers r ON r.s_suppkey = l.l_suppkey
WHERE p.p_size > 10
  AND (p.p_retailprice BETWEEN 100 AND 200 OR p.p_comment IS NOT NULL)
GROUP BY p.p_partkey, p.p_name, r.total_supply_cost
HAVING COUNT(DISTINCT fo.o_orderkey) > 5
ORDER BY total_quantity_sold DESC, avg_order_price DESC;