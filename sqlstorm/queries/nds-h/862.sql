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
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_type,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    ol.total_revenue,
    ol.item_count
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
JOIN 
    FilteredOrders ol ON ol.o_custkey = (
        SELECT 
            c.c_custkey 
        FROM 
            customer c 
        WHERE 
            c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'GERMANY')
            AND c.c_acctbal = (
                SELECT 
                    MAX(c2.c_acctbal) 
                FROM 
                    customer c2 
                WHERE 
                    c2.c_nationkey = c.c_nationkey
            )
        LIMIT 1
    )
WHERE 
    p.p_retailprice > 50.00 
ORDER BY 
    total_revenue DESC, item_count DESC;
