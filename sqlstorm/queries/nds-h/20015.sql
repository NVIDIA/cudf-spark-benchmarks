WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        SUM(ps.ps_availqty) AS total_avail
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size'
            ELSE CAST(p.p_size AS STRING)
        END AS size_description
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL)
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.region_name,
    fp.p_name,
    fp.size_description,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(s.avg_supplycost) AS avg_supply_cost
FROM 
    CustomerRegions cr
JOIN 
    customer c ON cr.c_custkey = c.c_custkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    FilteredParts fp ON l.l_partkey = fp.p_partkey
LEFT JOIN 
    SupplierCosts s ON fp.p_partkey = s.ps_partkey
WHERE 
    cr.region_name IS NOT NULL
    AND (l.l_returnflag = 'R' OR l.l_linestatus = 'O')
    AND EXISTS (
        SELECT 1
        FROM RankedOrders ro
        WHERE ro.o_orderkey = o.o_orderkey AND ro.rank_order <= 10
    )
GROUP BY 
    cr.region_name, fp.p_name, fp.size_description
HAVING 
    SUM(l.l_extendedprice) IS NOT NULL
ORDER BY 
    total_sales DESC, cr.region_name, fp.p_name;