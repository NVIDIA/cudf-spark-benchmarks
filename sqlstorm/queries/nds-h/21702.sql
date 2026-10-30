
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank,
        COUNT(*) OVER (PARTITION BY p.p_type) AS total_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueOrders AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_value) FROM (
            SELECT 
                SUM(l_extendedprice * (1 - l_discount)) AS total_value
            FROM 
                lineitem
            GROUP BY 
                l_orderkey
        ) AS avg_value)
),
SuppliersWithComments AS (
    SELECT 
        s.s_suppkey,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY LENGTH(s.s_comment) DESC) AS rn
    FROM 
        supplier s
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT cu.c_custkey) AS customer_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    COUNT(ho.o_orderkey) AS high_value_order_count,
    AVG(ho.total_value) AS avg_high_value
FROM 
    nation n 
LEFT JOIN 
    customer cu ON n.n_nationkey = cu.c_nationkey
LEFT JOIN 
    orders o ON cu.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    HighValueOrders ho ON o.o_orderkey = ho.o_orderkey
WHERE 
    EXISTS (
        SELECT 1
        FROM RankedSuppliers rs 
        WHERE rs.rank <= 3 
        AND rs.s_suppkey = l.l_suppkey
        HAVING MAX(rs.total_count) < 10
    )
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT cu.c_custkey) > 5
ORDER BY 
    returned_quantity DESC, 
    avg_high_value IS NULL ASC;
