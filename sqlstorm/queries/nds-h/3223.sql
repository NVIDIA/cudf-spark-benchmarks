WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) as rn,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s1.s_acctbal) 
            FROM supplier s1 
            WHERE s1.s_nationkey = s.s_nationkey
        )
),
TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate > (cast('1998-10-01' as date) - INTERVAL '1 year')
    GROUP BY 
        o.o_orderkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        tv.total_value,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        TotalOrderValue tv
    JOIN 
        orders o ON o.o_orderkey = tv.o_orderkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        tv.total_value > 10000
    GROUP BY 
        o.o_orderkey, tv.total_value
)
SELECT 
    rs.nation_name,
    rs.s_name,
    rs.s_acctbal,
    hvo.total_value,
    hvo.line_count
FROM 
    RankedSuppliers rs
LEFT JOIN 
    HighValueOrders hvo ON rs.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE ps.ps_availqty > 0 
        LIMIT 1
    )
WHERE 
    rs.rn = 1
ORDER BY 
    rs.nation_name, 
    rs.s_acctbal DESC;