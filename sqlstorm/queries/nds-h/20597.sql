WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
HighVolumeOrders AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_lineitems
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        COUNT(l.l_orderkey) > 5
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 50
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ns.n_name) AS nation_count,
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS total_sales,
    AVG(l.l_tax) AS average_tax,
    MAX(l.l_shipdate) AS latest_ship_date,
    (SELECT COUNT(*)
     FROM HighVolumeOrders hvo
     WHERE hvo.o_orderkey IN (
         SELECT o.o_orderkey 
         FROM orders o 
         JOIN lineitem l ON o.o_orderkey = l.l_orderkey
         WHERE l.l_returnflag = 'R'
     )
    ) AS returned_order_count
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    FilteredParts fp ON l.l_partkey = fp.p_partkey
WHERE 
    (l.l_shipdate > '1997-01-01' OR l.l_shipdate IS NULL) AND
    s.s_acctbal < (SELECT AVG(s2.s_acctbal) FROM supplier s2) AND
    COALESCE(l.l_returnflag, 'N') != 'Y'
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 10
ORDER BY 
    total_sales DESC
LIMIT 10;