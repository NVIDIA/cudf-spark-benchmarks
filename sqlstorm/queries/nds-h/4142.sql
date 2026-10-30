WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
), 

CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),

FilteredOrders AS (
    SELECT 
        cod.c_name,
        cod.total_spent,
        ROW_NUMBER() OVER (PARTITION BY cod.c_name ORDER BY cod.total_spent DESC) AS spending_rank
    FROM 
        CustomerOrderDetails cod
    WHERE 
        cod.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderDetails)
)

SELECT 
    r.r_name,
    COALESCE(SUM(fs.total_spent), 0) AS total_spent_by_region,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    MAX(s.s_acctbal) AS max_supplier_acctbal
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    FilteredOrders fs ON fs.c_name = s.s_name
WHERE 
    s.s_acctbal IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_spent_by_region DESC
LIMIT 10;