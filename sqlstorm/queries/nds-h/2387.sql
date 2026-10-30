WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        RankedSuppliers s
    JOIN 
        region r ON r.r_regionkey = (
            SELECT 
                n.n_regionkey
            FROM 
                nation n
            JOIN 
                customer c ON c.c_nationkey = n.n_nationkey
            WHERE 
                c.c_custkey = (
                    SELECT 
                        o.o_custkey
                    FROM 
                        orders o
                    WHERE 
                        o.o_orderkey IN (
                            SELECT 
                                DISTINCT l.l_orderkey
                            FROM 
                                lineitem l
                            WHERE 
                                l.l_shipdate >= DATE '1996-01-01' 
                                AND l.l_shipdate <= DATE '1996-12-31'
                        )
                    LIMIT 1
                )
        )
    WHERE 
        s.rn = 1
)
SELECT 
    COUNT(DISTINCT t.s_suppkey) AS unique_supplier_count,
    SUM(t.s_acctbal) AS total_acctbal,
    AVG(t.s_acctbal) AS avg_acctbal,
    MAX(t.s_acctbal) AS max_acctbal,
    MIN(t.s_acctbal) AS min_acctbal
FROM 
    TopSuppliers t
WHERE 
    t.s_acctbal IS NOT NULL
    AND t.s_acctbal > 1000
GROUP BY 
    t.r_regionkey
ORDER BY 
    unique_supplier_count DESC;