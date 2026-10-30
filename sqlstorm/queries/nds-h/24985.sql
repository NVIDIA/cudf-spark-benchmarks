WITH RecursivePartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_size,
        p.p_retailprice,
        p.p_type,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        N.N_NAME as nation_name,
        ROW_NUMBER() OVER (PARTITION BY N.N_NAME ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation N ON s.s_nationkey = N.n_nationkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_name IS NOT NULL
        )
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
), 
HighValueOrders AS (
    SELECT 
        od.o_orderkey,
        od.o_orderstatus,
        od.total_revenue,
        DENSE_RANK() OVER (ORDER BY od.total_revenue DESC) AS rank
    FROM 
        OrderDetails od
    WHERE 
        od.line_count > (
            SELECT AVG(line_count) 
            FROM OrderDetails
        )
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    sp.s_name AS supplier_name,
    pp.p_name AS part_name,
    pp.p_retailprice,
    COALESCE(hvo.total_revenue, 0) AS order_revenue,
    COALESCE(hvo.o_orderstatus, 'N/A') AS order_status
FROM 
    region r
JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierInfo sp ON sp.nation_name = n.n_name AND sp.rn <= 5
LEFT JOIN 
    partsupp ps ON sp.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    RecursivePartInfo pp ON ps.ps_partkey = pp.p_partkey AND pp.rn <= 3
LEFT JOIN 
    HighValueOrders hvo ON hvo.o_orderkey = ps.ps_partkey 
WHERE 
    (r.r_name LIKE '%N%' OR n.n_name IS NULL)
    AND (pp.p_size IS NULL OR pp.p_size BETWEEN 10 AND 20)
ORDER BY 
    r.r_name, n.n_name, sp.s_name, pp.p_retailprice DESC;