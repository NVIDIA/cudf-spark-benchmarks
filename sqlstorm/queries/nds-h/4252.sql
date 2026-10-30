WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
),
TotalRevenue AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_custkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(tr.total_revenue, 0) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        TotalRevenue tr ON c.c_custkey = tr.o_custkey
)
SELECT 
    cd.c_custkey,
    cd.c_name,
    cd.total_revenue,
    rs.s_name AS top_supplier,
    rs.s_acctbal AS supplier_balance
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedSuppliers rs ON cd.total_revenue > 10000 AND rs.rn = 1
WHERE 
    cd.total_revenue > (SELECT AVG(total_revenue) FROM TotalRevenue)
ORDER BY 
    cd.total_revenue DESC, 
    cd.c_name ASC;
