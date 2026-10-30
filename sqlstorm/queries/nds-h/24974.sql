
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
),
TotalRevenue AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            WHEN c.c_acctbal < 1000 THEN 'Low Balance'
            ELSE 'Sufficient Balance' 
        END AS balance_status
    FROM 
        customer c
    WHERE 
        c.c_mktsegment NOT IN ('AUTOMOBILE', 'BUILDING')
)
SELECT 
    n.n_name AS nation, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    COALESCE(SUM(TR.total_revenue), 0) AS total_revenue,
    AVG(RS.rank) AS avg_rank 
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers RS ON s.s_suppkey = RS.s_suppkey
LEFT JOIN 
    TotalRevenue TR ON TR.o_orderkey IN (SELECT o.o_orderkey 
                                          FROM orders o 
                                          JOIN customer c ON o.o_custkey = c.c_custkey
                                          WHERE c.c_address LIKE '123%' OR c.c_name IS NULL)
LEFT JOIN 
    FilteredCustomers FC ON s.s_suppkey = FC.c_custkey
WHERE 
    s.s_name IS NOT NULL 
GROUP BY 
    n.n_name 
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2 
    AND AVG(RS.rank) IS NOT NULL
ORDER BY 
    n.n_name;
