
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
)
SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    COALESCE(SUM(s.s_acctbal), 0) AS total_supplier_acctbal
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    RankedSuppliers s ON l.l_suppkey = s.s_suppkey AND s.rank <= 3
LEFT JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_quantity) > (
        SELECT 
            AVG(total_quantity) 
        FROM (
            SELECT 
                SUM(l.l_quantity) AS total_quantity
            FROM 
                lineitem l
            JOIN 
                orders o ON l.l_orderkey = o.o_orderkey
            GROUP BY 
                l.l_orderkey
        ) AS subquery
    )
ORDER BY 
    avg_price DESC
LIMIT 10;
