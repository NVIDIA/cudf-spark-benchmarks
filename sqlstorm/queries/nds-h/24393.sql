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
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > (
            SELECT AVG(ps_availqty)
            FROM partsupp ps_sub
            WHERE ps_sub.ps_partkey = p.p_partkey
        )
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_profit
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (
            SELECT AVG(total_profit)
            FROM (
                SELECT 
                    SUM(l_extendedprice * (1 - l_discount)) AS total_profit
                FROM 
                    lineitem
                GROUP BY 
                    l_orderkey
            ) AS avg_profit
        )
)
SELECT 
    r.r_regionkey,
    r.r_name,
    COUNT(DISTINCT h.o_orderkey) AS num_high_value_orders,
    COUNT(DISTINCT rs.s_suppkey) AS num_top_suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey 
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rn = 1
LEFT JOIN 
    HighValueOrders h ON h.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o 
        LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '1 year'
        AND l.l_returnflag = 'R'
    ) 
GROUP BY 
    r.r_regionkey, r.r_name
HAVING 
    COUNT(DISTINCT h.o_orderkey) > 5
ORDER BY 
    r.r_regionkey ASC, num_high_value_orders DESC;