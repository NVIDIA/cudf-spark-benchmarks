WITH  part_supplier AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(*) AS supplier_count,
        ROW_NUMBER() OVER(PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER(ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
region_nation AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        n.n_nationkey,
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name, n.n_nationkey, n.n_name
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    COALESCE(ps.s_name, 'No Supplier') AS supplier_name,
    COALESCE(ps.total_supplycost, 0) AS total_supplycost,
    cs.c_name AS customer_name,
    cs.total_spent,
    rn.supplier_count AS region_supplier_count
FROM part p
LEFT JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey AND ps.rank = 1
LEFT JOIN customer_order_summary cs ON ps.s_name = cs.c_name
LEFT JOIN region_nation rn ON ps.s_name = rn.n_name
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2
        WHERE p2.p_brand = p.p_brand
    )
AND rn.supplier_count > 5
ORDER BY total_supplycost DESC, total_spent ASC
LIMIT 100;
