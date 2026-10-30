WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_per_status
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
supplier_stats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost,
        ss.total_parts
    FROM supplier s
    JOIN supplier_stats ss ON s.s_suppkey = ss.s_suppkey
    WHERE ss.total_parts > 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(t.s_name, 'Unknown Supplier') AS supplier_name,
    CASE 
        WHEN l.l_discount > 0.1 THEN 'High Discount'
        ELSE 'Regular Price'
    END AS discount_category,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS avg_price
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN ranked_orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN top_suppliers t ON l.l_suppkey = t.s_suppkey
WHERE p.p_retailprice > 100
  AND (l.l_shipdate IS NULL OR l.l_shipdate < cast('1998-10-01' as date))
GROUP BY p.p_partkey, p.p_name, p.p_retailprice, t.s_name, l.l_discount
HAVING AVG(l.l_extendedprice) IS NOT NULL
  AND COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY avg_price DESC
LIMIT 10;