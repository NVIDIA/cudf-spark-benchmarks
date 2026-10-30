
WITH RankedSuppliers AS (
    SELECT 
        s.s_name, 
        s.s_acctbal, 
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        n.n_name AS nation_name,
        c.c_nationkey
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2) 
          AND n.n_name IS NOT NULL
)
SELECT 
    cd.c_name,
    cd.nation_name,
    COALESCE(ts.total_value, 0) AS total_order_value,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    rs.s_acctbal AS supplier_acctbal
FROM 
    CustomerDetails cd
LEFT JOIN 
    TotalOrderValue ts ON cd.c_custkey = ts.o_orderkey
LEFT JOIN 
    RankedSuppliers rs ON cd.c_nationkey = rs.s_nationkey AND rs.rank = 1
WHERE 
    cd.c_acctbal > 1000 
    AND (ts.total_value IS NULL OR ts.total_value > 5000)
ORDER BY 
    cd.c_name ASC, total_order_value DESC;
