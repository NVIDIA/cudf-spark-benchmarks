
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(NULLIF(p.p_size, 0), 1) AS size_non_zero
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
        OR p.p_brand LIKE 'Brand%'
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.c_name,
    fp.p_name,
    fp.p_brand,
    sc.total_supplycost,
    ROW_NUMBER() OVER (PARTITION BY r.o_orderkey ORDER BY sc.total_supplycost DESC) AS supply_rank
FROM 
    RankedOrders r
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    FilteredParts fp ON l.l_partkey = fp.p_partkey
LEFT JOIN 
    SupplierCosts sc ON fp.p_partkey = sc.ps_partkey
WHERE 
    r.order_rank <= 5
    AND (l.l_discount > 0.1 OR l.l_tax IS NULL)
GROUP BY 
    r.o_orderkey,
    r.o_orderdate,
    r.c_name,
    fp.p_name,
    fp.p_brand,
    sc.total_supplycost
ORDER BY 
    r.o_orderdate DESC, 
    sc.total_supplycost ASC
LIMIT 100;
