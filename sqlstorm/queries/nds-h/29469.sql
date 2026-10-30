
WITH SegmentCount AS (
    SELECT c.c_mktsegment, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_comment LIKE '%online%'
    GROUP BY c.c_mktsegment
),
TopRegions AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
    ORDER BY supplier_count DESC
    LIMIT 5
),
PartDetails AS (
    SELECT p.p_name, p.p_brand, ps.ps_availqty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_name, p.p_brand, ps.ps_availqty
    HAVING AVG(ps.ps_supplycost) < 100
)
SELECT rc.n_name AS r_name, sc.c_mktsegment, pc.p_name, pc.avg_supply_cost
FROM TopRegions rc
JOIN SegmentCount sc ON 1=1
JOIN PartDetails pc ON sc.order_count > 0
WHERE CHAR_LENGTH(pc.p_name) > 10 AND UPPER(pc.p_brand) LIKE 'A%'
ORDER BY rc.supplier_count DESC, sc.order_count DESC, pc.avg_supply_cost ASC;
