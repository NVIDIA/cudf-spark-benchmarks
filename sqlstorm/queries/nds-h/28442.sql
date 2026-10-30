
WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name AS supplier_name,
        s.s_nationkey AS supplier_nationkey,
        n.n_name AS supplier_nation,
        o.o_orderkey,
        c.c_custkey,
        c.c_name AS customer_name,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS returned_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE p.p_name LIKE '%widget%'
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, 
        p.p_type, p.p_size, p.p_container, 
        p.p_retailprice, p.p_comment, 
        ps.ps_availqty, ps.ps_supplycost, 
        s.s_name, s.s_nationkey, n.n_name, 
        o.o_orderkey, c.c_custkey, c.c_name
)
SELECT 
    p.p_name, 
    p.supplier_name, 
    p.total_revenue, 
    p.returned_items, 
    n.n_name AS region, 
    (p.p_retailprice - p.ps_supplycost) AS profit_margin
FROM PartDetails p
JOIN supplier s ON p.supplier_name = s.s_name
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE p.returned_items = 0
ORDER BY profit_margin DESC
LIMIT 10;
