WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        SUM(ps.ps_availqty) OVER (PARTITION BY p.p_partkey) AS total_avail_qty,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_sub.s_acctbal) FROM supplier s_sub)
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        CASE 
            WHEN o.o_orderstatus = 'O' THEN 'Open'
            WHEN o.o_orderstatus = 'F' THEN 'Filled'
            ELSE 'Unknown'
        END AS order_status
    FROM 
        orders o
    WHERE 
        EXTRACT(YEAR FROM o.o_orderdate) = 1997
        AND o.o_totalprice > (SELECT AVG(o_sub.o_totalprice) FROM orders o_sub)
),
FinalSummary AS (
    SELECT 
        np.n_nationkey,
        np.n_name,
        COUNT(DISTINCT lo.l_orderkey) AS order_count,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM 
        lineitem lo
    JOIN 
        orders o ON lo.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation np ON c.c_nationkey = np.n_nationkey
    WHERE 
        lo.l_returnflag = 'R'
    GROUP BY 
        np.n_nationkey, np.n_name
)
SELECT 
    r.r_name,
    COALESCE(SUM(fs.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT rp.p_partkey) AS part_count,
    MAX(rp.total_avail_qty) AS max_available
FROM 
    region r
LEFT JOIN 
    FinalSummary fs ON r.r_regionkey = fs.n_nationkey
LEFT JOIN 
    RankedParts rp ON rp.brand_rank <= 5
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC, part_count DESC
LIMIT 10;