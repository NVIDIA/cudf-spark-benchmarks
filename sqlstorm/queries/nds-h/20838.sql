WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
SupplierWithHighAverage AS (
    SELECT 
        s.s_suppkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        AVG(ps.ps_supplycost) > (
            SELECT 
                AVG(ps_supplycost) FROM partsupp
        )
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN cast('1998-10-01' as date) - INTERVAL '90 days' AND cast('1998-10-01' as date)
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    p.p_name,
    r.r_name AS region_name,
    SUM(f.total_price) AS total_revenue,
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers,
    COALESCE(RANK() OVER (ORDER BY SUM(f.total_price) DESC), 0) AS revenue_rank
FROM 
    part p
JOIN 
    filteredlineitems f ON p.p_partkey = f.l_partkey
LEFT JOIN 
    supplier s ON f.l_orderkey = s.s_suppkey 
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 10 AND 30
    AND p.p_comment NOT LIKE '%old%'
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 0)
GROUP BY 
    p.p_name, r.r_name
HAVING 
    SUM(f.total_price) > (
        SELECT 
            AVG(total_price)
        FROM 
            (SELECT 
                SUM(l_extendedprice * (1 - l_discount)) AS total_price
            FROM 
                lineitem 
            WHERE 
                l_shipdate >= '1997-01-01'
                GROUP BY 
                l_orderkey) AS avg_total
    )
ORDER BY 
    total_revenue DESC
LIMIT 10;