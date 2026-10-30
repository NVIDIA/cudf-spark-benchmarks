WITH  price_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_price,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey 
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) > 1000
),
nation_supplier AS (
    SELECT 
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
    HAVING 
        COUNT(DISTINCT s.s_suppkey) < 5
)
SELECT 
    ps.ps_partkey,
    COALESCE(p.p_name, 'No Name') AS part_name,
    ps.ps_availqty,
    ps.ps_supplycost,
    (SELECT SUM(l.l_quantity) 
     FROM lineitem l 
     WHERE l.l_partkey = ps.ps_partkey
     AND l.l_returnflag = 'R') AS total_returned_quantity,
    ns.supplier_count,
    ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) as supplier_rank
FROM 
    partsupp ps
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    nation_supplier ns ON ps.ps_suppkey = ns.n_nationkey
WHERE 
    ps.ps_supplycost NOT IN (SELECT DISTINCT ps_supplycost FROM partsupp WHERE ps_supplycost IS NOT NULL)
    AND (EXISTS (SELECT 1 FROM price_summary WHERE price_summary.p_partkey = ps.ps_partkey AND price_summary.total_price > 500)
    OR 1 = (SELECT COUNT(*) FROM part WHERE p_size IS NULL))
ORDER BY 
    p.p_retailprice DESC NULLS LAST,
    supplier_rank DESC;
