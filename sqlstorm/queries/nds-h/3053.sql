WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
),
SupplierParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        s.s_name AS supplier_name,
        s.s_acctbal
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS cust_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierParts sp ON sp.supplier_name = s.s_name
LEFT JOIN 
    lineitem l ON sp.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    c.c_acctbal IS NOT NULL
    AND l.l_returnflag = 'N'
    AND o.o_orderstatus IN ('O', 'F')
GROUP BY 
    r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (
        SELECT 
            AVG(total_revenue) 
        FROM 
            (SELECT 
                SUM(l2.l_extendedprice * (1 - l2.l_discount)) AS total_revenue
            FROM 
                lineitem l2
            JOIN 
                orders o2 ON l2.l_orderkey = o2.o_orderkey
            GROUP BY 
                o2.o_orderkey) AS revenue_summary
    )
ORDER BY 
    cust_count DESC, avg_supplier_balance DESC;