WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TotalRevenue AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        l.l_partkey
),
AvailableParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    rp.s_name,
    ap.p_name,
    ar.total_revenue,
    ap.total_available,
    CASE 
        WHEN ap.total_available = 0 THEN 'Out of Stock'
        ELSE 'In Stock'
    END AS availability_status
FROM 
    RankedSuppliers rp
JOIN 
    TotalRevenue ar ON ar.l_partkey = rp.s_suppkey
JOIN 
    AvailableParts ap ON ap.p_partkey = rp.s_suppkey
WHERE 
    rp.rank <= 5
ORDER BY 
    ar.total_revenue DESC, ap.p_name ASC;