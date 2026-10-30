
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerRanked AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(os.total_revenue) DESC) AS rank
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)
SELECT 
    r.r_name,
    cs.c_name,
    cs.rank,
    ss.total_cost,
    COALESCE(ss.part_count, 0) AS total_parts
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN CustomerRanked cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN SupplierStats ss ON ss.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_brand = 'Brand#12'
    )
    LIMIT 1
)
WHERE cs.rank <= 5 OR cs.rank IS NULL
ORDER BY r.r_name, cs.rank;
