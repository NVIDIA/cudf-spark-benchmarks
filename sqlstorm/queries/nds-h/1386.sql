WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
NationalRevenue AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(od.total_revenue) AS total_nation_revenue
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ns.s_suppkey) AS supplier_count,
    COALESCE(SUM(nr.total_nation_revenue), 0) AS total_revenue,
    AVG(COALESCE(s.s_acctbal, 0)) AS avg_supplier_balance
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers ns ON n.n_nationkey = ns.s_nationkey AND ns.rank <= 3
LEFT JOIN 
    NationalRevenue nr ON n.n_nationkey = nr.n_nationkey
LEFT JOIN 
    supplier s ON ns.s_suppkey = s.s_suppkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC, supplier_count DESC;